locals {
  roles = {
    admin  = "Full access to Grafana and Open WebUI administration"
    editor = "Can edit Grafana dashoards"
    viewer = "Read-only access"
  }
}

resource "keycloak_realm" "main" {
  realm                    = var.realm_name
  display_name             = "SoftServe Task 4"
  enabled                  = true
  registration_allowed     = false
  login_with_email_allowed = true
  ssl_required             = "external"
  sso_session_idle_timeout = "24h"
  sso_session_max_lifespan = "168h"
}

resource "keycloak_role" "realm" {
  for_each    = local.roles
  realm_id    = keycloak_realm.main.id
  name        = each.key
  description = each.value
}

resource "keycloak_group" "role" {
  for_each = local.roles
  realm_id = keycloak_realm.main.id
  name     = "${each.key}s"
}

resource "keycloak_group_roles" "role" {
  for_each = local.roles
  realm_id = keycloak_realm.main.id
  group_id = keycloak_group.role[each.key].id
  role_ids = [keycloak_role.realm[each.key].id]
}

resource "keycloak_default_groups" "main" {
  realm_id  = keycloak_realm.main.id
  group_ids = [keycloak_group.role["viewer"].id]
}
