resource "random_password" "grafana_admin" {
  length  = 32
  special = false
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_ssm_parameter" "grafana_admin_password" {
  name  = "/${lower(var.environment)}/grafana/admin-password"
  type  = "SecureString"
  value = random_password.grafana_admin.result

  tags = {
    Name = "${var.environment}-grafana-admin-password"
  }
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_ssm_parameter" "slack_webhook_url" {
  name  = "/${lower(var.environment)}/alertmanager/slack-webhook-url"
  type  = "SecureString"
  value = var.slack_webhook_url

  tags = {
    Name = "${var.environment}-slack-webhook-url"
  }
}

resource "random_password" "open_webui_db" {
  length  = 32
  special = false
}

resource "random_password" "open_webui_secret_key" {
  length  = 64
  special = false
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_ssm_parameter" "open_webui_db_password" {
  name  = "/${lower(var.environment)}/open-webui/db-password"
  type  = "SecureString"
  value = random_password.open_webui_db.result

  tags = {
    Name = "${var.environment}-open-webui-db-password"
  }
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_ssm_parameter" "open_webui_secret_key" {
  name  = "/${lower(var.environment)}/open-webui/secret-key"
  type  = "SecureString"
  value = random_password.open_webui_secret_key.result

  tags = {
    Name = "${var.environment}-open-webui-secret-key"
  }
}

resource "random_password" "keycloak_admin" {
  length  = 32
  special = false
}

resource "random_password" "keycloak_db" {
  length  = 32
  special = false
}

#tfsec:ignore:aws-ssm-secret-use-cusomer-key
resource "aws_ssm_parameter" "keycloak_admin_password" {
  name  = "/${lower(var.environment)}/keycloak/admin-password"
  type  = "SecureString"
  value = random_password.keycloak_admin.result

  tags = {
    Name = "${var.environment}-keycloak-admin-password"
  }
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_ssm_parameter" "keycloak_db_password" {
  name  = "/${lower(var.environment)}/keycloak/db-password"
  type  = "SecureString"
  value = random_password.keycloak_db.result

  tags = {
    Name = "${var.environment}-keycloak-db-password"
  }
}
