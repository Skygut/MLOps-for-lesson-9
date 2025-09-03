# AWS Core
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "eks-cluster"
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
  default     = "8.3.1"
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


# SSH Key Configuration for Git Repositories
variable "git_ssh_private_key_file" {
  description = "SSH private key for accessing Git repositories (base64 encoded or file path)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "git_ssh_known_hosts" {
  description = "SSH known hosts for Git repositories"
  type        = string
  default     = ""
}

variable "git_repositories" {
  description = "List of Git repositories to configure with SSH access"
  type = list(object({
    name   = string
    url    = string
    type   = optional(string, "git")
    project = optional(string, "default")
    sshPrivateKeyFile = optional(string, "")
  }))
  default = []
}



# ArgoCD Applications Configuration
variable "argocd_applications" {
  description = "List of ArgoCD Applications to create"
  type = list(object({
    name      = string
    namespace = optional(string, "default")
    project   = optional(string, "default")
    source = object({
      repo_url        = string
      target_revision = optional(string, "HEAD")
      path            = optional(string, ".")
      helm = optional(object({
        release_name   = optional(string)
        value_files    = optional(list(string), [])
        values         = optional(string, "")
        parameters     = optional(map(string), {})
      }))
    })
    destination = object({
      server    = optional(string, "https://kubernetes.default.svc")
      namespace = string
    })
    sync_policy = optional(object({
      automated = optional(object({
        prune       = optional(bool, false)
        self_heal   = optional(bool, false)
        allow_empty = optional(bool, false)
      }))
      sync_options = optional(list(string), [])
      retry = optional(object({
        limit = optional(number, 5)
        backoff = optional(object({
          duration     = optional(string, "5s")
          factor       = optional(number, 2)
          max_duration = optional(string, "3m")
        }))
      }))
    }))
    ignore_differences = optional(list(object({
      group             = optional(string)
      kind              = optional(string)
      name              = optional(string)
      namespace         = optional(string)
      json_pointers     = optional(list(string), [])
      jq_path_expressions = optional(list(string), [])
    })), [])
  }))
  default = []
}