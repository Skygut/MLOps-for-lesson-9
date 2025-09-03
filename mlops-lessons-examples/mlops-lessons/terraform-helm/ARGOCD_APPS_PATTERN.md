# ArgoCD Apps - App of Apps Pattern

This guide explains how to use the ArgoCD Apps Helm chart to implement the "App of Apps" pattern for managing multiple ArgoCD applications in a structured way.

## Overview

The App of Apps pattern is a GitOps best practice where:
- A single "parent" ArgoCD Application manages multiple "child" applications
- All applications are defined as code in a Git repository
- Changes to applications are made through Git commits
- ArgoCD automatically synchronizes all applications

## Benefits

✅ **Centralized Management**: All applications defined in one place  
✅ **GitOps Workflow**: All changes tracked in Git  
✅ **Scalability**: Easy to add/remove applications  
✅ **Environment Management**: Different app sets per environment  
✅ **Dependency Management**: Control application deployment order  

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Git Repo      │    │   ArgoCD Apps    │    │  Child Apps     │
│                 │    │   (Parent)       │    │                 │
│ argocd-apps/    │───▶│                  │───▶│ ├── Frontend     │
│ ├── frontend.yml│    │  Monitors repo   │    │ ├── Backend      │
│ ├── backend.yml │    │  Creates child   │    │ ├── Database     │
│ └── database.yml│    │  applications    │    │ └── Monitoring   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Configuration

### 1. Enable ArgoCD Apps

```hcl
# terraform.tfvars
argocd_apps_enabled = true
argocd_apps_source = {
  repo_url        = "git@github.com:myorg/argocd-apps.git"
  target_revision = "main"
  path            = "apps/"
}
```

### 2. Repository Structure

Create a Git repository with your application definitions:

```
argocd-apps/
├── apps/
│   ├── production/
│   │   ├── frontend.yaml
│   │   ├── backend.yaml
│   │   ├── database.yaml
│   │   └── monitoring.yaml
│   ├── staging/
│   │   ├── frontend.yaml
│   │   ├── backend.yaml
│   │   └── database.yaml
│   └── development/
│       ├── frontend.yaml
│       └── backend.yaml
├── charts/
│   └── app-template/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
└── environments/
    ├── production/
    ├── staging/
    └── development/
```

### 3. Application Examples

#### Simple Application (`apps/production/frontend.yaml`)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: frontend-prod
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: git@github.com:myorg/frontend.git
    targetRevision: v2.1.0
    path: k8s/
  destination:
    server: https://kubernetes.default.svc
    namespace: frontend-prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

#### Helm Application (`apps/production/backend.yaml`)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backend-prod
  namespace: argocd
spec:
  project: default
  source:
    repoURL: git@github.com:myorg/backend-charts.git
    targetRevision: main
    path: charts/backend/
    helm:
      releaseName: backend-prod
      valueFiles:
        - values-production.yaml
      values: |
        replicaCount: 3
        image:
          tag: "v1.5.2"
        resources:
          requests:
            memory: "512Mi"
            cpu: "200m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      parameters:
        - name: service.type
          value: LoadBalancer
        - name: database.host
          value: postgres.database.svc.cluster.local
  destination:
    server: https://kubernetes.default.svc
    namespace: backend-prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

#### Kustomize Application (`apps/production/database.yaml`)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: database-prod
  namespace: argocd
spec:
  project: default
  source:
    repoURL: git@github.com:myorg/database-configs.git
    targetRevision: main
    path: overlays/production/
  destination:
    server: https://kubernetes.default.svc
    namespace: database-prod
  syncPolicy:
    # Manual sync for database changes
    syncOptions:
      - CreateNamespace=true
  ignoreDifferences:
    - group: apps
      kind: StatefulSet
      jsonPointers:
        - /spec/volumeClaimTemplates
```

## Advanced Patterns

### 1. Environment-Specific Apps

Use different paths for different environments:

```hcl
# Production
argocd_apps_source = {
  repo_url = "git@github.com:myorg/argocd-apps.git"
  path     = "apps/production/"
}

# Staging
argocd_apps_source = {
  repo_url = "git@github.com:myorg/argocd-apps.git"
  path     = "apps/staging/"
}
```

### 2. Helm Chart for Apps

Use a Helm chart to template application definitions:

```hcl
argocd_apps_source = {
  repo_url = "git@github.com:myorg/argocd-apps.git"
  path     = "charts/apps/"
  helm = {
    release_name = "production-apps"
    value_files  = ["values-production.yaml"]
    values = <<-EOT
      environment: production
      applications:
        frontend:
          enabled: true
          version: "v2.1.0"
        backend:
          enabled: true
          version: "v1.5.2"
          replicas: 3
        monitoring:
          enabled: true
    EOT
  }
}
```

**Chart structure:**
```
charts/apps/
├── Chart.yaml
├── values.yaml
├── values-production.yaml
├── values-staging.yaml
└── templates/
    ├── frontend.yaml
    ├── backend.yaml
    └── monitoring.yaml
```

**Template example (`templates/frontend.yaml`):**
```yaml
{{- if .Values.applications.frontend.enabled }}
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: frontend-{{ .Values.environment }}
  namespace: {{ .Release.Namespace }}
spec:
  project: default
  source:
    repoURL: {{ .Values.applications.frontend.repoURL }}
    targetRevision: {{ .Values.applications.frontend.version }}
    path: k8s/
  destination:
    server: https://kubernetes.default.svc
    namespace: frontend-{{ .Values.environment }}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
{{- end }}
```

### 3. Application Dependencies

Control deployment order using sync waves:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: database-prod
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "0"  # Deploy first
spec:
  # ... database configuration
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backend-prod
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "1"  # Deploy after database
spec:
  # ... backend configuration
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: frontend-prod
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "2"  # Deploy last
spec:
  # ... frontend configuration
```

## Complete Example

### Terraform Configuration

```hcl
# terraform.tfvars
argocd_apps_enabled = true
argocd_apps_source = {
  repo_url        = "git@github.com:myorg/platform-apps.git"
  target_revision = "main"
  path            = "environments/production/"
  helm = {
    release_name = "production-platform"
    value_files  = ["values.yaml"]
    parameters = {
      "environment" = "production"
      "cluster"     = "prod-us-west-2"
    }
  }
}
argocd_apps_sync_policy = {
  automated = {
    prune     = true
    self_heal = true
  }
  sync_options = ["CreateNamespace=true"]
}
```

### Repository Structure

```
platform-apps/
├── environments/
│   ├── production/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── core/
│   │       │   ├── cert-manager.yaml
│   │       │   ├── ingress-nginx.yaml
│   │       │   └── external-dns.yaml
│   │       ├── monitoring/
│   │       │   ├── prometheus.yaml
│   │       │   ├── grafana.yaml
│   │       │   └── alertmanager.yaml
│   │       └── applications/
│   │           ├── web-app.yaml
│   │           ├── api-service.yaml
│   │           └── worker-service.yaml
│   ├── staging/
│   └── development/
├── base-applications/
│   ├── cert-manager/
│   ├── prometheus/
│   └── grafana/
└── README.md
```

## Best Practices

### 1. Repository Organization

- **Separate repositories**: Keep app definitions separate from application code
- **Environment branches**: Use branches or paths for different environments
- **Consistent naming**: Use clear, consistent naming conventions
- **Documentation**: Include README files for each application

### 2. Application Configuration

- **Resource limits**: Always set resource requests and limits
- **Health checks**: Configure proper liveness and readiness probes
- **Security**: Use NetworkPolicies, PodSecurityPolicies, and RBAC
- **Monitoring**: Include monitoring and alerting configuration

### 3. Sync Strategies

- **Production**: Use manual sync for critical applications
- **Development**: Use automatic sync for rapid iteration
- **Staging**: Mixed approach based on testing requirements
- **Dependencies**: Use sync waves for ordered deployments

### 4. Security

- **SSH Keys**: Use dedicated SSH keys for ArgoCD
- **RBAC**: Implement proper role-based access control
- **Secrets**: Use external secret management (e.g., External Secrets Operator)
- **Network**: Implement network policies between applications

## Troubleshooting

### Common Issues

1. **Apps not syncing**
   - Check repository access and SSH keys
   - Verify path and file structure
   - Check ArgoCD logs

2. **Resource conflicts**
   - Use unique names across environments
   - Check for namespace collisions
   - Verify RBAC permissions

3. **Dependency issues**
   - Use sync waves for ordered deployment
   - Check application health status
   - Review resource dependencies

### Debug Commands

```bash
# Check Apps application status
kubectl get application apps -n argocd

# List all applications managed by Apps
kubectl get applications -n argocd

# Check specific application
argocd app get frontend-prod

# Manual sync all applications
argocd app sync apps
argocd app sync -l app.kubernetes.io/instance=apps

# Check application resources
argocd app resources frontend-prod
```

## Migration from Individual Applications

To migrate from individual ArgoCD applications to the App of Apps pattern:

1. **Create apps repository** with application definitions
2. **Deploy ArgoCD Apps** using this Terraform configuration
3. **Verify applications** are created and synced
4. **Remove individual applications** from Terraform
5. **Update CI/CD pipelines** to use the new repository structure

This provides a centralized, scalable approach to managing multiple ArgoCD applications while maintaining GitOps best practices.
