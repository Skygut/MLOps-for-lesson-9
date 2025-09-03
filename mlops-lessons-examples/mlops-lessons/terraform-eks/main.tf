# Data sources
data "aws_availability_zones" "available" {
  region = var.aws_region
  state  = "available"
}

data "aws_caller_identity" "current" {}

# S3 bucket for Terraform state (keeping existing resource)
resource "aws_s3_bucket" "tf_state" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = {
    Name        = var.bucket_name
    CreatedBy   = "Terraform"
    Description = "S3 bucket for Terraform state"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket_public_access" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# VPC Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = var.private_subnets_cidr
  public_subnets  = var.public_subnets_cidr

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true


  # EKS requires these tags on subnets
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }

  tags = {
    Environment                                 = var.environment
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}


module "ebs_csi_driver_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"

  name = "ebs-csi"

  attach_ebs_csi_policy = true

  oidc_providers = {
    this = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}



# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.0.0"

  region             = var.aws_region
  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  enable_cluster_creator_admin_permissions = true
  endpoint_public_access                   = true
  endpoint_private_access                  = true
  endpoint_public_access_cidrs             = ["0.0.0.0/0"]

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    mlops-cpu-main = {
      
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.instance_types

      min_size     = 3
      max_size     = 10
      desired_size = 3
      node_repair_config = {
        auto_repair = true
      }
      disk_size = 100
      disk_type = "gp3"
      disk_iops = 3000
      disk_throughput = 125
      disk_encryption = false
      iam_role_attach_cni_policy = true
    }
  }



  # Cluster add-ons
  addons = {
    coredns = {
      most_recent = true
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      most_recent = true
      resolve_conflicts = "OVERWRITE"

    }
    vpc-cni = {
      most_recent = true
      resolve_conflicts = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      most_recent = true
      resolve_conflicts = "OVERWRITE"
      preserve_on_delete = false
      pod_identity_association = [{
        service_account = "ebs-csi-controller-sa"
        namespace = "kube-system"
        role_arn = module.ebs_csi_driver_irsa.arn
      }]
    }
  }

  tags = {
    Environment = var.environment
  }
}

# ArgoCD Helm Release
resource "helm_release" "argocd" {
  depends_on = [kubernetes_namespace.argocd]
  
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  
  # Wait for deployment to be ready
  wait          = true
  wait_for_jobs = true
  timeout       = 600
  
  values = [
    yamlencode({
      global = {
        domain = var.argocd_domain
      }
      
      configs = {
        params = {
          "server.insecure" = var.argocd_insecure
        }
      }
      
      server = {
        service = {
          type = var.argocd_service_type
          annotations = var.argocd_service_annotations
        }
        
        ingress = {
          enabled = var.argocd_ingress_enabled
          annotations = var.argocd_ingress_annotations
          hosts = [
            {
              host = var.argocd_domain
              paths = [
                {
                  path = "/"
                  pathType = "Prefix"
                }
              ]
            }
          ]
          tls = var.argocd_ingress_tls
        }
      }
      
      dex = {
        enabled = false
      }
      
      notifications = {
        enabled = false
      }
      
      applicationSet = {
        enabled = var.argocd_applicationset_enabled
      }
    })
  ]
}
