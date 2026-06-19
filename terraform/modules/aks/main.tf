resource "azurerm_kubernetes_cluster" "this" {
  name                = "${var.prefix}-aks"
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = "${var.prefix}-aks"
  kubernetes_version  = var.kubernetes_version
  node_resource_group = "${var.prefix}-aks-nodes"

  default_node_pool {
    name                 = "system"
    vm_size              = var.node_size
    vnet_subnet_id       = var.subnet_id
    orchestrator_version = var.kubernetes_version
    auto_scaling_enabled = true
    min_count            = var.node_min_count
    max_count            = var.node_max_count
    max_pods             = 50
    os_disk_size_gb      = 64

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "calico"
    pod_cidr            = var.pod_cidr
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
    outbound_type       = "userAssignedNATGateway"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  tags = var.tags
}
