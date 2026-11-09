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
