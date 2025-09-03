# AWS Configuration
variable "aws_region" {
  description = "The AWS region to deploy the EKS cluster"
  type        = string
  default     = "eu-west-2"
}

# S3 Bucket Variables (existing resources)
variable "bucket_name" {
  description = "The name of the S3 bucket for Terraform state"
  type        = string
  default     = "mlops-tf-eks-state"
}

variable "force_destroy" {
  description = "Whether to force destroy the S3 bucket even if it contains objects"
  type        = bool
  default     = true
}

# EKS Cluster Configuration
variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "eks-cluster"
}

variable "kubernetes_version" {
  description = "The Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.33"
}

variable "environment" {
  description = "Environment tag for resources"
  type        = string
  default     = "dev"
}

# VPC Configuration (free tier optimized)
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets_cidr" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

# Node Group Configuration (free tier optimized)
variable "instance_types" {
  description = "EC2 instance types for worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "instance_types_gpu" {
  description = "EC2 instance types for worker nodes"
  type        = list(string)
  default     = ["g4dn.xlarge"]
}

variable "min_nodes" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "max_nodes" {
  description = "Maximum number of nodes"
  type        = number
  default     = 1
}

variable "desired_nodes" {
  description = "Desired number of nodes"
  type        = number
  default     = 1
}

# ArgoCD Configuration
variable "argocd_namespace" {
  description = "Kubernetes namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Version of the ArgoCD Helm chart"
  type        = string
  default     = "5.51.6"
}

variable "argocd_domain" {
  description = "Domain name for ArgoCD server"
  type        = string
  default     = "argocd.local"
}

variable "argocd_insecure" {
  description = "Run ArgoCD server in insecure mode"
  type        = bool
  default     = true
}

variable "argocd_service_type" {
  description = "Kubernetes service type for ArgoCD server"
  type        = string
  default     = "LoadBalancer"
  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.argocd_service_type)
    error_message = "Service type must be one of: ClusterIP, NodePort, LoadBalancer."
  }
}

variable "argocd_service_annotations" {
  description = "Annotations for ArgoCD server service"
  type        = map(string)
  default     = {}
}

variable "argocd_ingress_enabled" {
  description = "Enable ingress for ArgoCD server"
  type        = bool
  default     = false
}

variable "argocd_ingress_annotations" {
  description = "Annotations for ArgoCD server ingress"
  type        = map(string)
  default     = {}
}

variable "argocd_ingress_tls" {
  description = "TLS configuration for ArgoCD server ingress"
  type        = list(object({
    secretName = string
    hosts      = list(string)
  }))
  default = []
}

variable "argocd_applicationset_enabled" {
  description = "Enable ArgoCD ApplicationSet controller"
  type        = bool
  default     = true
}