locals {
  grafana_url                   = data.terraform_remote_state.infra.outputs.grafana_domain_url
  keycloak_oidc_url             = "${data.terraform_remote_state.infra.outputs.keycloak_url}/realms/${var.keycloak_realm}/protocol/openid-connect"
  keycloak_backchannel_oidc_url = "${data.terraform_remote_state.infra.outputs.keycloak_private_url}/realms/${var.keycloak_realm}/protocol/openid-connect"
}

data "aws_ssm_parameter" "grafana_oidc_client_secret" {
  name = data.terraform_remote_state.infra.outputs.grafana_oidc_client_secret_parameter
}

resource "grafana_sso_settings" "keycloak" {
  provider_name = "generic_oauth"

  oauth2_settings {
    name                  = "Keycloak"
    enabled               = true
    client_id             = var.keycloak_client_id
    client_secret         = data.aws_ssm_parameter.grafana_oidc_client_secret.value
    auth_url              = "${local.keycloak_oidc_url}/auth"
    token_url             = "${local.keycloak_backchannel_oidc_url}/token"
    api_url               = "${local.keycloak_backchannel_oidc_url}/userinfo"
    signout_redirect_url  = "${local.keycloak_oidc_url}/logout?client_id=${var.keycloak_client_id}&post_logout_redirect_uri=${urlencode("${local.grafana_url}/login")}"
    scopes                = "openid email profile"
    use_pkce              = true
    use_refresh_token     = true
    allow_sign_up         = true
    login_attribute_path  = "preferred_username"
    name_attribute_path   = "name"
    email_attribute_path  = "email"
    role_attribute_path   = "contains(roles[*], 'admin') && 'Admin' || contains(roles[*], 'editor') && 'Editor' || contains(roles[*], 'viewer') && 'Viewer'"
    role_attribute_strict = true
  }
}
