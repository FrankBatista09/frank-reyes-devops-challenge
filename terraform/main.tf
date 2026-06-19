resource "azurerm_resource_group" "this" {
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

resource "random_string" "acr_suffix" {
  length  = 6
  special = false
  upper   = false
}

module "networking" {
  source              = "./modules/networking"
  prefix              = var.prefix
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  vnet_cidr           = var.vnet_cidr
  aks_subnet_cidr     = var.aks_subnet_cidr
  tags                = var.tags
}

module "gateway" {
  source              = "./modules/gateway"
  prefix              = var.prefix
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  subnet_id           = module.networking.aks_subnet_id
  tags                = var.tags
}

module "monitoring" {
  source              = "./modules/monitoring"
  prefix              = var.prefix
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  retention_in_days   = var.log_retention_in_days
  tags                = var.tags
}

module "acr" {
  source              = "./modules/acr"
  name                = "${replace(var.prefix, "-", "")}acr${random_string.acr_suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  sku                 = var.acr_sku
  tags                = var.tags
}

module "aks" {
  source                     = "./modules/aks"
  prefix                     = var.prefix
  resource_group_name        = azurerm_resource_group.this.name
  location                   = var.location
  kubernetes_version         = var.kubernetes_version
  node_size                  = var.node_size
  node_min_count             = var.node_min_count
  node_max_count             = var.node_max_count
  subnet_id                  = module.networking.aks_subnet_id
  pod_cidr                   = var.pod_cidr
  service_cidr               = var.service_cidr
  dns_service_ip             = var.dns_service_ip
  log_analytics_workspace_id = module.monitoring.workspace_id
  tags                       = var.tags

  depends_on = [module.gateway]
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = module.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = module.aks.kubelet_identity_object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_public_ip" "ingress" {
  name                = "${var.prefix}-ingress-pip"
  resource_group_name = module.aks.node_resource_group
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

module "k8s_addons" {
  source                = "./modules/k8s-addons"
  ingress_nginx_version = var.ingress_nginx_version
  cert_manager_version  = var.cert_manager_version
  load_balancer_ip      = azurerm_public_ip.ingress.ip_address

  depends_on = [module.aks]
}

module "dns" {
  source              = "./modules/dns"
  resource_group_name = azurerm_resource_group.this.name
  zone_name           = var.dns_zone_name
  record_name         = var.dns_record_name
  ingress_ip          = azurerm_public_ip.ingress.ip_address
  tags                = var.tags
}
