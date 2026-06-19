output "nat_gateway_id" {
  value = azurerm_nat_gateway.this.id
}

output "public_ip" {
  value = azurerm_public_ip.nat.ip_address
}

output "public_ip_id" {
  value = azurerm_public_ip.nat.id
}
