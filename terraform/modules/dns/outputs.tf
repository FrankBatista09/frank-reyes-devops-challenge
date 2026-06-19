output "zone_name" {
  description = "DNS zone name."
  value       = azurerm_dns_zone.this.name
}

output "name_servers" {
  description = "Azure name servers to delegate at the domain registrar."
  value       = azurerm_dns_zone.this.name_servers
}

output "app_fqdn" {
  description = "Fully-qualified hostname of the A record (no trailing dot)."
  value       = trimsuffix(azurerm_dns_a_record.app.fqdn, ".")
}
