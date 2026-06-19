variable "subscription_id" {
  description = "Azure subscription ID (passed via TF_VAR_subscription_id)."
  type        = string
  default     = null
}

variable "prefix" {
  description = "Name prefix applied to all resources."
  type        = string
  default     = "devsu-demo"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "eastus2"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version."
  type        = string
  default     = "1.35"
}

variable "node_size" {
  description = "VM size for the default node pool."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "node_min_count" {
  description = "Minimum nodes (cluster autoscaler floor, >=2 for HA)."
  type        = number
  default     = 2
}

variable "node_max_count" {
  description = "Maximum nodes (cluster autoscaler ceiling)."
  type        = number
  default     = 5
}

variable "vnet_cidr" {
  description = "Address space of the VNet."
  type        = string
  default     = "10.20.0.0/16"
}

variable "aks_subnet_cidr" {
  description = "Address prefix of the AKS node subnet."
  type        = string
  default     = "10.20.1.0/24"
}

variable "pod_cidr" {
  description = "Overlay CIDR for pod IPs (Azure CNI Overlay)."
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services."
  type        = string
  default     = "10.0.0.0/16"
}

variable "dns_service_ip" {
  description = "Cluster DNS service IP (must be inside service_cidr)."
  type        = string
  default     = "10.0.0.10"
}

variable "acr_sku" {
  description = "Azure Container Registry SKU."
  type        = string
  default     = "Standard"
}

variable "log_retention_in_days" {
  description = "Log Analytics retention."
  type        = number
  default     = 30
}

variable "ingress_nginx_version" {
  description = "ingress-nginx Helm chart version."
  type        = string
  default     = "4.11.3"
}

variable "cert_manager_version" {
  description = "cert-manager Helm chart version."
  type        = string
  default     = "v1.15.3"
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default = {
    project   = "devsu-demo-devops-nodejs"
    managedBy = "terraform"
    owner     = "frank-reyes"
  }
}
