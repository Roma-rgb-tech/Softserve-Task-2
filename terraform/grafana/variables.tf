variable "aws_region" {
  description = "AWS region for the provider and the CloudWatch data souce"
  type        = string
  default     = "eu-north-1"
}

variable "keycloak_realm" {
  description = "Keycloak realm that Grafana users sign in to"
  type        = string
  default     = "softserve"
}

variable "keycloak_client_id" {
  description = "Keycloak OIDC client ID for Grafana"
  type        = string
  default     = "grafana"
}
