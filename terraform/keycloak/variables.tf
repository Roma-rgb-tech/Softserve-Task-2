variable "aws_region" {
  description = "AWS region for the provider and SSM parameters"
  type        = string
  default     = "eu-north-1"
}

variable "realm_name" {
  description = "Keycloak realm for Grafana and Open WebUI users"
  type        = string
  default     = "softserve"
}

variable "github_client_id" {
  description = "Client ID of the Github OAuth App used as identity provider"
  type        = string
}

variable "github_client_secret" {
  description = "Client secret of the Github OAth App used as identity provider"
  type        = string
  sensitive   = true
}

variable "gitlab_client_id" {
  description = "Application ID of the GitLab application used as a identity provider"
  type        = string
}

variable "gitlab_client_secret" {
  description = "Secret of the GitLab application used as identity provider"
  type        = string
  sensitive   = true
}
