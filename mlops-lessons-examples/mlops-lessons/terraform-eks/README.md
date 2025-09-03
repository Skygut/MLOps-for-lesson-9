# AWS EKS Cluster with Terraform (Free Tier Optimized)

This Terraform configuration deploys an AWS EKS cluster using the **latest EKS module (v21.0.0)** with minimal configuration optimized for AWS Free Tier accounts.

## 🚀 **What This Creates**

- **EKS Cluster**: Managed Kubernetes control plane (v1.29)
- **VPC**: Dedicated VPC with public/private subnets across 2 AZs
- **Node Group**: Single t3.micro instance (free tier eligible)
- **Add-ons**: CoreDNS, kube-proxy, and VPC CNI
- **S3 Bucket**: For potential Terraform state storage

## 💰 **Free Tier Optimization**

This configuration is specifically designed for AWS Free Tier:

- **Instance Type**: `t3.micro` (750 hours/month free)
- **Node Count**: 1 node (min=1, max=1, desired=1)
- **Disk Size**: 20GB EBS (within 30GB free tier)
- **Network**: Single NAT gateway, 2 AZs only
- **Minimal Resources**: Streamlined for cost efficiency

⚠️ **Important**: EKS control plane costs ~$0.10/hour (~$73/month) - **NOT covered by free tier**

## 📋 **Prerequisites**

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.5.7
3. **kubectl** for cluster management

## 🛠️ **Quick Start**

### 1. **Clone and Configure**

```bash
cd terraform-eks
cp terraform.tfvars.example terraform.tfvars
```

### 2. **Edit Configuration**

Edit `terraform.tfvars` with your specific values:

```hcl
# AWS Configuration
aws_region = "eu-west-2"

# EKS Cluster Configuration
cluster_name       = "eks-cluster"
kubernetes_version = "1.29"
environment        = "dev"

# Node Group Configuration (free tier optimized)
instance_types = ["t3.micro"]
min_nodes      = 1
max_nodes      = 1
desired_nodes  = 1
```

### 3. **Deploy**

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### 4. **Configure kubectl**

After successful deployment:

```bash
aws eks --region eu-west-2 update-kubeconfig --name eks-cluster
```

Verify the connection:

```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

## 🔧 **Configuration Variables**

| Variable | Description | Default | Free Tier Notes |
|----------|-------------|---------|-----------------|
| `aws_region` | AWS region | `eu-west-1` | Choose closest region |
| `cluster_name` | EKS cluster name | `eks-cluster` | Keep short for resource naming |
| `kubernetes_version` | K8s version | `1.29` | Latest supported version |
| `instance_types` | Node instance types | `["t3.micro"]` | **Free tier eligible** |
| `min_nodes` | Minimum nodes | `1` | **Cost optimized** |
| `max_nodes` | Maximum nodes | `1` | **Single node for free tier** |
| `desired_nodes` | Desired nodes | `1` | **Cost optimized** |

## 🏗️ **Architecture**

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Region                           │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    VPC (10.0.0.0/16)                   ││
│  │  ┌─────────────────┐    ┌─────────────────────────────┐ ││
│  │  │   Public AZ-A   │    │      Private AZ-A           │ ││
│  │  │  10.0.1.0/24    │    │     10.0.101.0/24           │ ││
│  │  │                 │    │  ┌─────────────────────────┐ │ ││
│  │  │  ┌──────────┐   │    │  │    EKS Node Group       │ │ ││
│  │  │  │NAT Gateway│   │    │  │    (t3.micro x1)        │ │ ││
│  │  │  └──────────┘   │    │  └─────────────────────────┘ │ ││
│  │  └─────────────────┘    └─────────────────────────────┘ ││
│  │  ┌─────────────────┐    ┌─────────────────────────────┐ ││
│  │  │   Public AZ-B   │    │      Private AZ-B           │ ││
│  │  │  10.0.2.0/24    │    │     10.0.102.0/24           │ ││
│  │  └─────────────────┘    └─────────────────────────────┘ ││
│  └─────────────────────────────────────────────────────────┘│
│               │                                             │
│    ┌─────────────────────────────────────────────────────┐  │
│    │              EKS Control Plane                      │  │
│    │              (Managed by AWS)                       │  │
│    └─────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 💡 **Cost Management**

### **Monthly Cost Estimate (Free Tier)**
- **EKS Control Plane**: ~$73/month (not free)
- **t3.micro Instance**: $0 (750 hours free)
- **EBS Storage (20GB)**: $0 (30GB free)
- **NAT Gateway**: ~$32/month
- **Data Transfer**: Minimal (15GB free)

**Total**: ~$105/month

### **Cost Optimization Tips**
1. **Destroy when not in use**: `terraform destroy`
2. **Set up billing alerts**: Monitor AWS spend
3. **Use AWS Cost Explorer**: Track usage patterns
4. **Consider spot instances**: For non-production (not in this config)

## 🔒 **Security Features**

- **Private Node Groups**: Workers in private subnets
- **IAM Integration**: Proper service roles
- **Security Groups**: Restrictive network access
- **VPC**: Isolated network environment
- **Encryption**: EKS encryption at rest

## 🔍 **Monitoring & Debugging**

```bash
# Check cluster status
aws eks describe-cluster --name eks-cluster --region eu-west-1

# List node groups
aws eks list-nodegroups --cluster-name eks-cluster --region eu-west-1

# View cluster info
kubectl cluster-info

# Check nodes
kubectl get nodes -o wide

# View all pods
kubectl get pods --all-namespaces
```

## 🧹 **Cleanup**

To destroy all resources:

```bash
terraform destroy
```

**⚠️ Warning**: This will delete the entire cluster and VPC.

## 🆘 **Troubleshooting**

### **Common Issues**

1. **Insufficient IAM permissions**: Ensure AWS credentials have EKS permissions
2. **Region availability**: Verify EKS is available in your chosen region
3. **Instance type availability**: t3.micro availability varies by region
4. **Name conflicts**: Ensure cluster names are unique

### **Useful Commands**

```bash
# Re-initialize if modules change
terraform init -upgrade

# Validate configuration
terraform validate

# Format configuration
terraform fmt

# Check Terraform state
terraform show
```

## 🔗 **References**

- [AWS EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [Terraform AWS EKS Module v21.0.0](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/21.0.0)
- [AWS Free Tier](https://aws.amazon.com/free/)
- [EKS Pricing](https://aws.amazon.com/eks/pricing/)

---

**Built with ❤️ using Terraform AWS EKS Module v21.0.0**