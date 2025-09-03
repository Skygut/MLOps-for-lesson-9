# Data sources
data "aws_caller_identity" "current" {}
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}


# ArgoCD Namespace
resource "kubernetes_namespace" "argocd" {
  depends_on = [data.aws_eks_cluster.cluster]
  metadata {
    name = var.argocd_namespace
    
    labels = {
      name = var.argocd_namespace
    }
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
        env = [
          {
            name = "HELM_EXPERIMENTAL_OCI"
            value = "1"
          }
        ]
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

# SSH Private Key Secret for Git Repository Access
resource "kubernetes_secret" "argocd_repo_ssh_key" {
  count      = var.git_ssh_private_key_file != "" ? 1 : 0
  depends_on = [kubernetes_namespace.argocd]
  
  metadata {
    name      = "argocd-repo-ssh-key"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repo-creds"
    }
  }
  
  type = "Opaque"
  
  data = {
    type          = "git"
    url           = "git@github.com"  # This will match any GitHub repository
    sshPrivateKey = file(var.git_ssh_private_key_file)
    insecure      = "false"
    enableLfs     = "true"
  }
}

# Repository Secrets for specific repositories
resource "kubernetes_secret" "argocd_repo_secrets" {
  count      = length(var.git_repositories)
  depends_on = [kubernetes_namespace.argocd]
  
  metadata {
    name      = "argocd-repo-${var.git_repositories[count.index].name}"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }
  
  type = "Opaque"
  
  data = {
    name          = var.git_repositories[count.index].name
    url           = var.git_repositories[count.index].url
    type          = var.git_repositories[count.index].type
    project       = var.git_repositories[count.index].project
    sshPrivateKey = file(var.git_repositories[count.index].sshPrivateKeyFile)
    insecure      = "false"
    enableLfs     = "true"
  }
}

# ArgoCD Applications
resource "kubernetes_manifest" "argocd_applications" {
  count      = length(var.argocd_applications)
  depends_on = [helm_release.argocd]
  
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = var.argocd_applications[count.index].name
      namespace = kubernetes_namespace.argocd.metadata[0].name
      labels = {
        "app.kubernetes.io/name" = var.argocd_applications[count.index].name
      }
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = var.argocd_applications[count.index].project
      source = merge(
        {
          repoURL        = var.argocd_applications[count.index].source.repo_url
          targetRevision = var.argocd_applications[count.index].source.target_revision
          path           = var.argocd_applications[count.index].source.path
        },
        var.argocd_applications[count.index].source.helm != null ? {
          helm = merge(
            var.argocd_applications[count.index].source.helm.release_name != null ? {
              releaseName = var.argocd_applications[count.index].source.helm.release_name
            } : {},
            length(var.argocd_applications[count.index].source.helm.value_files) > 0 ? {
              valueFiles = var.argocd_applications[count.index].source.helm.value_files
            } : {},
            var.argocd_applications[count.index].source.helm.values != "" ? {
              values = var.argocd_applications[count.index].source.helm.values
            } : {},
            length(var.argocd_applications[count.index].source.helm.parameters) > 0 ? {
              parameters = [
                for key, value in var.argocd_applications[count.index].source.helm.parameters : {
                  name  = key
                  value = value
                }
              ]
            } : {}
          )
        } : {}
      )
      destination = {
        server    = var.argocd_applications[count.index].destination.server
        namespace = var.argocd_applications[count.index].destination.namespace
      }
      syncPolicy = var.argocd_applications[count.index].sync_policy != null ? merge(
        var.argocd_applications[count.index].sync_policy.automated != null ? {
          automated = {
            prune      = var.argocd_applications[count.index].sync_policy.automated.prune
            selfHeal   = var.argocd_applications[count.index].sync_policy.automated.self_heal
            allowEmpty = var.argocd_applications[count.index].sync_policy.automated.allow_empty
          }
        } : {},
        length(var.argocd_applications[count.index].sync_policy.sync_options) > 0 ? {
          syncOptions = var.argocd_applications[count.index].sync_policy.sync_options
        } : {},
        var.argocd_applications[count.index].sync_policy.retry != null ? {
          retry = merge(
            {
              limit = var.argocd_applications[count.index].sync_policy.retry.limit
            },
            var.argocd_applications[count.index].sync_policy.retry.backoff != null ? {
              backoff = {
                duration    = var.argocd_applications[count.index].sync_policy.retry.backoff.duration
                factor      = var.argocd_applications[count.index].sync_policy.retry.backoff.factor
                maxDuration = var.argocd_applications[count.index].sync_policy.retry.backoff.max_duration
              }
            } : {}
          )
        } : {}
      ) : null
      ignoreDifferences = length(var.argocd_applications[count.index].ignore_differences) > 0 ? [
        for diff in var.argocd_applications[count.index].ignore_differences : merge(
          diff.group != null ? { group = diff.group } : {},
          diff.kind != null ? { kind = diff.kind } : {},
          diff.name != null ? { name = diff.name } : {},
          diff.namespace != null ? { namespace = diff.namespace } : {},
          length(diff.json_pointers) > 0 ? { jsonPointers = diff.json_pointers } : {},
          length(diff.jq_path_expressions) > 0 ? { jqPathExpressions = diff.jq_path_expressions } : {}
        )
      ] : null
    }
  }
}

# Create destination namespaces for applications
resource "kubernetes_namespace" "app_namespaces" {
  for_each = toset([
    for app in var.argocd_applications : app.destination.namespace
    if app.destination.namespace != "default" && app.destination.namespace != kubernetes_namespace.argocd.metadata[0].name
  ])
  
  metadata {
    name = each.value
    labels = {
      "managed-by" = "argocd"
    }
  }
}

resource "helm_release" "argocd_apps" {
  depends_on = [kubernetes_namespace.argocd]
  name       = "argocd-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.2"
  namespace  = "argocd"
  lifecycle {
    ignore_changes = [
      values
    ]
  }
  values = [<<EOF
applications:
  argocd-apps:
    namespace: argocd
    project: "default"
    source:
      repoURL: "git@github.com:vilovgh/mlflow-argocd-apps.git"
      targetRevision: "HEAD"
      path: "."
      helm:
        valueFiles:
          - "envs/dev/apps.yaml"
    destination:
      server: https://kubernetes.default.svc
      namespace: "argocd"
    syncPolicy:
      automated:
        prune: true
        selfHeal: true
      syncOptions:
        - CreateNamespace=true
    revisionHistoryLimit: 10
EOF
]

}