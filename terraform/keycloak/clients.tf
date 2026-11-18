locals {
  grafana_url    = data.terraform_remote_state.infra.outputs.grafana_domain_url
  open_webui_url = data.terraform_remote_state.infra.outputs.open_webui_domain_url
}

data "aws_ssm_parameter" "grafana_client_secret" {
  name = data.terraform_remote_state.infra.outputs.grafana_oidc_client_secret_parameter
}

data "aws_ssm_parameter" "open_webui_client_secret" {
  name = data.terraform_remote_state.infra.outputs.open_webui_oidc_client_secret_parameter
}

resource "keycloak_openid_client" "grafana" {
  realm_id                        = keycloak_realm.main.id
  client_id                       = "grafana"
  name                            = "Grafana"
  enabled                         = true
  access_type                     = "CONFIDENTIAL"
  client_secret                   = data.aws_ssm_parameter.grafana_client_secret.value
  standard_flow_enabled           = true
  direct_access_grants_enabled    = false
  root_url                        = local.grafana_url
  base_url                        = local.grafana_url
  valid_redirect_uris             = ["${local.grafana_url}/login/generic_oauth"]
  valid_post_logout_redirect_uris = ["${local.grafana_url}/login"]
  web_origins                     = [local.grafana_url]
}

resource "keycloak_openid_client" "open_webui" {
  realm_id                        = keycloak_realm.main.id
  client_id                       = "open-webui"
  name                            = "Open WebUI"
  enabled                         = true
  access_type                     = "CONFIDENTIAL"
  client_secret                   = data.aws_ssm_parameter.open_webui_client_secret.value
  standard_flow_enabled           = true
  direct_access_grants_enabled    = false
  root_url                        = local.open_webui_url
  base_url                        = local.open_webui_url
  valid_redirect_uris             = ["${local.open_webui_url}/oauth/oidc/callback"]
  valid_post_logout_redirect_uris = ["${local.open_webui_url}/auth"]
  web_origins                     = [local.open_webui_url]
}

resource "keycloak_openid_user_realm_role_protocol_mapper" "roles" {
  for_each = {
    grafana    = keycloak_openid_client.grafana.id
    open_webui = keycloak_openid_client.open_webui.id
  }

  realm_id            = keycloak_realm.main.id
  client_id           = each.value
  name                = "realm-roles"
  claim_name          = "roles"
  multivalued         = true
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
}
