resource "keycloak_oidc_github_identity_provider" "github" {
  realm         = keycloak_realm.main.id
  display_name  = "GitHub"
  client_id     = var.github_client_id
  client_secret = var.github_client_secret
  trust_email   = true
  sync_mode     = "IMPORT"
}

resource "keycloak_oidc_identity_provider" "gitlab" {
  realm              = keycloak_realm.main.id
  alias              = "gitlab"
  display_name       = "GitLab"
  client_id          = var.gitlab_client_id
  client_secret      = var.gitlab_client_secret
  issuer             = "https://gitlab.com"
  authorization_url  = "https://gitlab.com/oauth/authorize"
  token_url          = "https://gitlab.com/oauth/token"
  user_info_url      = "https://gitlab.com/oauth/userinfo"
  jwks_url           = "https://gitlab.com/oauth/discovery/keys"
  validate_signature = true
  default_scopes     = "openid profile email"
  trust_email        = true
  sync_mode          = "IMPORT"
}
