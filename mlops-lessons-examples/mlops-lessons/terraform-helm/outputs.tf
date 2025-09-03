# ArgoCD Outputs
output "argocd_namespace" {
  description = "Kubernetes namespace where ArgoCD is deployed"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_server_service_name" {
  description = "Name of the ArgoCD server service"
  value       = "${helm_release.argocd.name}-server"
}

output "argocd_server_service_type" {
  description = "Type of the ArgoCD server service"
  value       = var.argocd_service_type
}

output "argocd_domain" {
  description = "Domain configured for ArgoCD"
  value       = var.argocd_domain
}

output "argocd_helm_release_status" {
  description = "Status of the ArgoCD Helm release"
  value       = helm_release.argocd.status
}

output "argocd_access_instructions" {
  description = "Instructions for accessing ArgoCD"
  value = var.argocd_service_type == "LoadBalancer" ? "ArgoCD will be accessible via LoadBalancer. Get the external IP with: kubectl get svc ${helm_release.argocd.name}-server -n ${kubernetes_namespace.argocd.metadata[0].name}" : var.argocd_service_type == "NodePort" ? "ArgoCD will be accessible via NodePort. Get the node port with: kubectl get svc ${helm_release.argocd.name}-server -n ${kubernetes_namespace.argocd.metadata[0].name}" : "ArgoCD is accessible via ClusterIP. Use port-forward: kubectl port-forward svc/${helm_release.argocd.name}-server -n ${kubernetes_namespace.argocd.metadata[0].name} 8080:443"
}

output "argocd_initial_admin_password_command" {
  description = "Command to get the initial admin password for ArgoCD"
  value       = "kubectl -n ${kubernetes_namespace.argocd.metadata[0].name} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}