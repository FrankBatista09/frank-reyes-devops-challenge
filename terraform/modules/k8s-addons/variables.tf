variable "ingress_nginx_version" {
  type    = string
  default = "4.11.3"
}

variable "cert_manager_version" {
  type    = string
  default = "v1.15.3"
}

variable "load_balancer_ip" {
  description = "Static public IP for the ingress LoadBalancer (must exist in the AKS node resource group)."
  type        = string
}
