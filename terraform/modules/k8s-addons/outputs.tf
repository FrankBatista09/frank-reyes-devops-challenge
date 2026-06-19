output "ingress_namespace" {
  value = helm_release.ingress_nginx.namespace
}

output "cert_manager_namespace" {
  value = helm_release.cert_manager.namespace
}
