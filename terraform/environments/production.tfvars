prefix             = "devsu-demo"
location           = "eastus2"
kubernetes_version = "1.31"

node_size      = "Standard_D2s_v5"
node_min_count = 2
node_max_count = 5

vnet_cidr       = "10.20.0.0/16"
aks_subnet_cidr = "10.20.1.0/24"
pod_cidr        = "10.244.0.0/16"
service_cidr    = "10.0.0.0/16"
dns_service_ip  = "10.0.0.10"

acr_sku               = "Standard"
log_retention_in_days = 30

ingress_nginx_version = "4.11.3"
cert_manager_version  = "v1.15.3"

tags = {
  project     = "devsu-demo-devops-nodejs"
  environment = "production"
  managedBy   = "terraform"
  owner       = "frank-reyes"
}
