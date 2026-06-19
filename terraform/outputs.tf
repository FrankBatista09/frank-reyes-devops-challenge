output "resource_group" {
  description = "Resource group name."
  value       = azurerm_resource_group.this.name
}

output "acr_name" {
  description = "ACR name (use as ACR_NAME in CI/CD)."
  value       = module.acr.name
}

output "acr_login_server" {
  description = "ACR login server, e.g. devsudemoacrxxxxxx.azurecr.io"
  value       = module.acr.login_server
}

output "aks_cluster_name" {
  description = "AKS cluster name."
  value       = module.aks.name
}

output "aks_node_resource_group" {
  description = "Auto-managed node resource group."
  value       = module.aks.node_resource_group
}

output "nat_gateway_public_ip" {
  description = "Deterministic egress IP of the cluster."
  value       = module.gateway.public_ip
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource id."
  value       = module.monitoring.workspace_id
}

output "get_credentials_command" {
  description = "Command to fetch the kubeconfig for kubectl."
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.this.name} --name ${module.aks.name}"
}

output "dns_name_servers" {
  description = "Delegate these name servers at your domain registrar."
  value       = module.dns.name_servers
}

output "app_fqdn" {
  description = "Public hostname of the app (A record)."
  value       = module.dns.app_fqdn
}

output "ingress_public_ip" {
  description = "Static public IP bound to the ingress LoadBalancer."
  value       = azurerm_public_ip.ingress.ip_address
}
