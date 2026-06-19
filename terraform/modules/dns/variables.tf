variable "zone_name" {
  description = "DNS zone (registered domain) name, e.g. nimbuslab.dev."
  type        = string
}

variable "record_name" {
  description = "A record name (subdomain). Use \"@\" for the apex."
  type        = string
  default     = "app"
}

variable "ingress_ip" {
  description = "Public IP of the ingress-nginx LoadBalancer."
  type        = string
}

variable "record_ttl" {
  description = "TTL of the A record in seconds."
  type        = number
  default     = 300
}

variable "resource_group_name" {
  description = "Resource group that holds the DNS zone."
  type        = string
}

variable "tags" {
  description = "Tags applied to the DNS zone."
  type        = map(string)
  default     = {}
}
