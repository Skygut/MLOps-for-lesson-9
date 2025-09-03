# ArgoCD SSH Key Configuration for Git Repositories

This Terraform configuration creates Kubernetes secrets for ArgoCD to authenticate with private Git repositories using SSH keys.

## Prerequisites

1. An SSH key pair for accessing your Git repositories
2. Access to the Git repository (GitHub, GitLab, etc.)
3. Kubernetes cluster with ArgoCD installed

## Setup Steps

### 1. Generate SSH Key (if you don't have one)

```bash
# Generate a new SSH key specifically for ArgoCD
ssh-keygen -t rsa -b 4096 -C "argocd@yourdomain.com" -f ~/.ssh/argocd_rsa

# Or use ed25519 (recommended)
ssh-keygen -t ed25519 -C "argocd@yourdomain.com" -f ~/.ssh/argocd_ed25519
```

### 2. Add SSH Public Key to Git Repository

#### For GitHub:
1. Go to your repository → Settings → Deploy keys
2. Click "Add deploy key"
3. Copy the content of your public key (`~/.ssh/argocd_rsa.pub`)
4. Paste it and give it a title like "ArgoCD Deploy Key"
5. Check "Allow write access" if ArgoCD needs to write to the repo

#### For GitLab:
1. Go to your project → Settings → Repository → Deploy Keys
2. Add the public key content

### 3. Configure Terraform Variables

Create a `terraform.tfvars` file based on the example:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and configure:

```hcl
# Option 1: Use file() function to read SSH key
git_ssh_private_key = file("~/.ssh/argocd_rsa")

# Option 2: Base64 encode and provide directly
# git_ssh_private_key = "LS0tLS1CRUdJTi..."

# Configure your repositories
git_repositories = [
  {
    name    = "my-app"
    url     = "git@github.com:yourusername/my-app.git"
    type    = "git"
    project = "default"
  }
]
```

### 4. Apply Terraform Configuration

```bash
terraform init
terraform plan
terraform apply
```

## How It Works

The configuration creates two types of Kubernetes secrets:

### 1. Repository Credentials Secret (`argocd-repo-ssh-key`)
- **Type**: `repo-creds`
- **Purpose**: Provides SSH credentials for all repositories matching a URL pattern
- **URL Pattern**: `git@github.com` (matches all GitHub repositories)

### 2. Repository-Specific Secrets (`argocd-repo-{name}`)
- **Type**: `repository`
- **Purpose**: Defines specific repositories with their SSH credentials
- **Created**: One per repository in `git_repositories` variable

## Security Best Practices

1. **Use dedicated SSH keys**: Create separate SSH keys specifically for ArgoCD
2. **Minimal permissions**: Use deploy keys with read-only access when possible
3. **Key rotation**: Regularly rotate SSH keys
4. **Sensitive variables**: Mark SSH keys as sensitive in Terraform

## Troubleshooting

### SSH Key Format Issues
Ensure your SSH key is properly formatted:
- Private key should start with `-----BEGIN OPENSSH PRIVATE KEY-----` or `-----BEGIN RSA PRIVATE KEY-----`
- No extra whitespace or newlines
- Properly base64 encoded if using that option

### ArgoCD Not Recognizing Repository
1. Check that the secret has the correct labels:
   ```yaml
   labels:
     argocd.argoproj.io/secret-type: repository
   ```
2. Verify the repository URL matches exactly
3. Check ArgoCD logs for authentication errors

### Testing SSH Connection
Test SSH connectivity from your local machine:
```bash
ssh -T git@github.com -i ~/.ssh/argocd_rsa
```

## Example Secret Structure

The created secrets will look like this:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: argocd-repo-ssh-key
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repo-creds
type: Opaque
data:
  type: Z2l0  # base64 encoded "git"
  url: Z2l0QGdpdGh1Yi5jb20=  # base64 encoded "git@github.com"
  sshPrivateKey: <base64-encoded-ssh-private-key>
  insecure: ZmFsc2U=  # base64 encoded "false"
  enableLfs: dHJ1ZQ==  # base64 encoded "true"
```

## Additional Configuration

### Known Hosts (Optional)
For additional security, you can provide SSH known hosts:

```hcl
git_ssh_known_hosts = "github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ=="
```

### Repository Projects
You can organize repositories into different ArgoCD projects:

```hcl
git_repositories = [
  {
    name    = "frontend-app"
    url     = "git@github.com:org/frontend.git"
    project = "frontend"
  },
  {
    name    = "backend-api"
    url     = "git@github.com:org/backend.git"
    project = "backend"
  }
]
```
