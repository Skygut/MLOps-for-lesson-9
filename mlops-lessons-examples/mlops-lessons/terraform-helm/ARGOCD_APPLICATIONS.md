# ArgoCD Applications with Terraform

This guide explains how to create and manage ArgoCD Applications using Terraform to deploy Kubernetes manifests automatically.

## Overview

ArgoCD Applications are declarative specifications that define how to deploy applications to Kubernetes clusters. This Terraform configuration creates ArgoCD Applications that can:

- Deploy plain Kubernetes YAML manifests
- Deploy Helm charts
- Deploy Kustomize applications
- Automatically sync changes from Git repositories
- Manage application lifecycle and rollbacks

## Configuration Structure

### Application Definition

```hcl
argocd_applications = [
  {
    name      = "my-app"              # Application name
    namespace = "default"             # ArgoCD namespace (usually 'default')
    project   = "default"             # ArgoCD project
    
    source = {
      repo_url        = "git@github.com:org/repo.git"  # Git repository URL
      target_revision = "main"                         # Branch, tag, or commit
      path            = "k8s/"                         # Path within repository
      
      # Optional: Helm configuration
      helm = {
        release_name = "my-release"
        value_files  = ["values-prod.yaml"]
        values       = "replicaCount: 3"
        parameters   = {
          "service.type" = "LoadBalancer"
        }
      }
    }
    
    destination = {
      server    = "https://kubernetes.default.svc"  # Kubernetes API server
      namespace = "production"                       # Target namespace
    }
    
    sync_policy = {
      automated = {
        prune     = true   # Delete resources not in Git
        self_heal = true   # Automatically fix drift
      }
      sync_options = ["CreateNamespace=true"]
    }
  }
]
```

## Application Types

### 1. Plain Kubernetes Manifests

For applications with standard Kubernetes YAML files:

```hcl
{
  name = "web-app"
  source = {
    repo_url        = "git@github.com:myorg/web-app.git"
    target_revision = "v1.2.3"
    path            = "k8s/manifests/"
  }
  destination = {
    namespace = "web-app"
  }
}
```

**Repository structure:**
```
k8s/manifests/
├── deployment.yaml
├── service.yaml
├── ingress.yaml
└── configmap.yaml
```

### 2. Helm Charts

For applications packaged as Helm charts:

```hcl
{
  name = "my-helm-app"
  source = {
    repo_url        = "git@github.com:myorg/helm-charts.git"
    target_revision = "main"
    path            = "charts/my-app"
    helm = {
      release_name = "my-app-prod"
      value_files  = ["values-production.yaml"]
      values = <<-EOT
        replicaCount: 3
        image:
          tag: "v2.1.0"
        resources:
          requests:
            memory: "512Mi"
            cpu: "200m"
      EOT
      parameters = {
        "service.type"     = "LoadBalancer"
        "ingress.enabled"  = "true"
        "autoscaling.enabled" = "true"
      }
    }
  }
  destination = {
    namespace = "my-app"
  }
}
```

**Repository structure:**
```
charts/my-app/
├── Chart.yaml
├── values.yaml
├── values-production.yaml
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    └── ingress.yaml
```

### 3. Kustomize Applications

For applications using Kustomize overlays:

```hcl
{
  name = "kustomize-app"
  source = {
    repo_url        = "git@github.com:myorg/k8s-configs.git"
    target_revision = "main"
    path            = "overlays/production"
  }
  destination = {
    namespace = "kustomize-app"
  }
}
```

**Repository structure:**
```
overlays/production/
├── kustomization.yaml
├── deployment-patch.yaml
└── configmap-patch.yaml

base/
├── kustomization.yaml
├── deployment.yaml
├── service.yaml
└── configmap.yaml
```

## Sync Policies

### Automated Sync

Enable automatic synchronization:

```hcl
sync_policy = {
  automated = {
    prune       = true   # Delete resources not in Git
    self_heal   = true   # Fix configuration drift
    allow_empty = false  # Don't sync if no resources
  }
}
```

### Manual Sync

Disable automatic sync (manual deployment only):

```hcl
sync_policy = {
  # No automated block = manual sync only
  sync_options = ["PrunePropagationPolicy=foreground"]
}
```

### Sync Options

Common sync options:

```hcl
sync_policy = {
  sync_options = [
    "CreateNamespace=true",           # Create namespace if it doesn't exist
    "PrunePropagationPolicy=foreground", # Delete resources in foreground
    "PruneLast=true",                 # Prune resources after sync
    "ApplyOutOfSyncOnly=true",        # Only apply out-of-sync resources
    "RespectIgnoreDifferences=true",  # Respect ignore differences
    "Validate=false"                  # Skip kubectl validation
  ]
}
```

### Retry Configuration

Configure retry behavior for failed syncs:

```hcl
sync_policy = {
  retry = {
    limit = 5
    backoff = {
      duration     = "5s"
      factor       = 2
      max_duration = "3m"
    }
  }
}
```

## Ignore Differences

Ignore specific resource differences:

```hcl
ignore_differences = [
  {
    group = "apps"
    kind  = "Deployment"
    json_pointers = [
      "/spec/replicas"  # Ignore replica count changes (for HPA)
    ]
  },
  {
    group = ""
    kind  = "Service"
    name  = "my-service"
    json_pointers = [
      "/spec/clusterIP"  # Ignore cluster IP changes
    ]
  },
  {
    kind = "Secret"
    jq_path_expressions = [
      ".metadata.annotations"  # Ignore all annotations on secrets
    ]
  }
]
```

## Best Practices

### 1. Repository Organization

```
my-app-repo/
├── src/                    # Application source code
├── k8s/
│   ├── base/              # Base Kubernetes manifests
│   ├── overlays/
│   │   ├── development/   # Dev environment
│   │   ├── staging/       # Staging environment
│   │   └── production/    # Production environment
│   └── charts/            # Helm charts
└── .argocd/               # ArgoCD specific configs
```

### 2. Environment-Specific Applications

Create separate applications for each environment:

```hcl
argocd_applications = [
  {
    name = "my-app-dev"
    source = {
      repo_url = "git@github.com:myorg/my-app.git"
      path     = "k8s/overlays/development"
    }
    destination = { namespace = "my-app-dev" }
  },
  {
    name = "my-app-staging"
    source = {
      repo_url = "git@github.com:myorg/my-app.git"
      path     = "k8s/overlays/staging"
    }
    destination = { namespace = "my-app-staging" }
  },
  {
    name = "my-app-prod"
    source = {
      repo_url = "git@github.com:myorg/my-app.git"
      path     = "k8s/overlays/production"
    }
    destination = { namespace = "my-app-prod" }
    sync_policy = {
      # Disable auto-sync for production
      sync_options = ["CreateNamespace=true"]
    }
  }
]
```

### 3. Security Considerations

- Use SSH keys for private repositories
- Limit ArgoCD service account permissions
- Use different ArgoCD projects for different teams
- Enable RBAC for ArgoCD access

### 4. Monitoring and Alerts

- Monitor application sync status
- Set up alerts for sync failures
- Use ArgoCD webhooks for notifications
- Monitor application health checks

## Troubleshooting

### Common Issues

1. **Sync Failed - Permission Denied**
   - Check SSH key configuration
   - Verify repository access permissions
   - Check ArgoCD service account RBAC

2. **Application OutOfSync**
   - Review ignore differences configuration
   - Check for manual changes in cluster
   - Verify Git repository state

3. **Resources Not Created**
   - Check namespace exists
   - Verify RBAC permissions
   - Check resource manifests syntax

### Debug Commands

```bash
# Check application status
kubectl get applications -n argocd

# Describe application details
kubectl describe application my-app -n argocd

# Check ArgoCD server logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server

# Manual sync via CLI
argocd app sync my-app

# Check application resources
argocd app resources my-app
```

## Examples

### Complete Example: Microservices Application

```hcl
argocd_applications = [
  # Frontend service
  {
    name = "frontend"
    source = {
      repo_url        = "git@github.com:myorg/frontend.git"
      target_revision = "v2.1.0"
      path            = "k8s/"
    }
    destination = { namespace = "frontend" }
    sync_policy = {
      automated = { prune = true, self_heal = true }
      sync_options = ["CreateNamespace=true"]
    }
  },
  
  # Backend API
  {
    name = "backend-api"
    source = {
      repo_url        = "git@github.com:myorg/backend-api.git"
      target_revision = "main"
      path            = "helm-chart/"
      helm = {
        release_name = "backend-api"
        value_files  = ["values-prod.yaml"]
        parameters = {
          "image.tag" = "v1.5.2"
          "database.host" = "postgres.database.svc.cluster.local"
        }
      }
    }
    destination = { namespace = "backend" }
    sync_policy = {
      automated = { prune = true, self_heal = true }
      sync_options = ["CreateNamespace=true"]
    }
  },
  
  # Shared infrastructure
  {
    name = "infrastructure"
    source = {
      repo_url        = "git@github.com:myorg/k8s-infrastructure.git"
      target_revision = "main"
      path            = "manifests/"
    }
    destination = { namespace = "infrastructure" }
    sync_policy = {
      sync_options = ["CreateNamespace=true"]
      # Manual sync for infrastructure changes
    }
  }
]
```

This configuration provides a complete GitOps workflow where:
- All applications are defined as code
- Changes are tracked in Git
- ArgoCD automatically syncs applications
- Each application can have different sync policies
- Namespaces are automatically created
