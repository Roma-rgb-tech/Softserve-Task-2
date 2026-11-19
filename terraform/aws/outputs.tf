output "bastion_public_ip" {
  value = module.bastion.public_ip
}

output "monitoring_public_ip" {
  value = module.monitoring.public_ip
}

output "grafana_url" {
  value = "http://${module.monitoring.public_ip}:3000"
}

output "grafana_admin_password_parameter" {
  value = aws_ssm_parameter.grafana_admin_password.name
}

output "monitoring_security_group_id" {
  value = aws_security_group.monitoring.id
}

output "alb_dns_name" {
  value = module.llm.alb_dns_name
}

output "alerts_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "route53_name_servers" {
  value = aws_route53_zone.main.name_servers
}

output "grafana_domain_url" {
  value = module.web_alb.urls["grafana"]
}

output "open_webui_domain_url" {
  value = module.web_alb.urls["open-webui"]
}

output "keycloak_url" {
  value = module.web_alb.urls["keycloak"]
}

output "keycloak_admin_password_parameter" {
  value = aws_ssm_parameter.keycloak_admin_password.name
}

output "web_alb_security_group_id" {
  value = aws_security_group.web_alb.id
}

output "grafana_oidc_client_secret_parameter" {
  value = aws_ssm_parameter.grafana_oidc_client_secret.name
}

output "open_webui_oidc_client_secret_parameter" {
  value = aws_ssm_parameter.open_webui_oidc_client_secret.name
}

output "keycloak_private_url" {
  value = "http://${module.keycloak.private_ip}:8080"
}
