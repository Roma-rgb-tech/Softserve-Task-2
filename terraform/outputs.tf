output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "monitoring_public_ip" {
  value = aws_instance.monitoring.public_ip
}

output "grafana_url" {
  value = "http://${aws_instance.monitoring.public_ip}:3000"
}

output "grafana_admin_password_parameter" {
  value = aws_ssm_parameter.grafana_admin_password.name
}

output "monitoring_security_group_id" {
  value = aws_security_group.monitoring.id
}

output "alb_dns_name" {
  value = aws_lb.llm.dns_name
}

output "alerts_topic_arn" {
  value = aws_sns_topic.alerts.arn
}
