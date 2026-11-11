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
