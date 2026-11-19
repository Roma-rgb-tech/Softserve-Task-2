moved {
  from = aws_db_subnet_group.main
  to   = module.database.aws_db_subnet_group.this
}

moved {
  from = aws_db_instance.postgres
  to   = module.database.aws_db_instance.this
}

moved {
  from = aws_instance.bastion
  to   = module.bastion.aws_instance.this
}

moved {
  from = aws_instance.monitoring
  to   = module.monitoring.aws_instance.this
}

moved {
  from = aws_iam_role.monitoring
  to   = module.monitoring.aws_iam_role.this
}

moved {
  from = aws_iam_role_policy_attachment.monitoring_ssm
  to   = module.monitoring.aws_iam_role_policy_attachment.ssm
}

moved {
  from = aws_iam_instance_profile.monitoring
  to   = module.monitoring.aws_iam_instance_profile.this
}

moved {
  from = aws_iam_role_policy.monitoring_cloudwatch_read
  to   = module.monitoring.aws_iam_role_policy.this["cloudwatch-read"]
}

moved {
  from = aws_iam_role_policy.monitoring_grafana_secret_read
  to   = module.monitoring.aws_iam_role_policy.this["grafana-secret-read"]
}

moved {
  from = aws_iam_role_policy.monitoring_sns_publish
  to   = module.monitoring.aws_iam_role_policy.this["sns-publish"]
}

moved {
  from = aws_iam_role_policy.monitoring_slack_webhook_read
  to   = module.monitoring.aws_iam_role_policy.this["slack-webhook-read"]
}

moved {
  from = aws_instance.keycloak
  to   = module.keycloak.aws_instance.this
}

moved {
  from = aws_iam_role.keycloak
  to   = module.keycloak.aws_iam_role.this
}

moved {
  from = aws_iam_role_policy_attachment.keycloak_ssm
  to   = module.keycloak.aws_iam_role_policy_attachment.ssm
}

moved {
  from = aws_iam_instance_profile.keycloak
  to   = module.keycloak.aws_iam_instance_profile.this
}

moved {
  from = aws_iam_role_policy.keycloak_secrets_read
  to   = module.keycloak.aws_iam_role_policy.this["secrets-read"]
}

moved {
  from = aws_instance.open_webui
  to   = module.open_webui.aws_instance.this
}

moved {
  from = aws_iam_role.open_webui
  to   = module.open_webui.aws_iam_role.this
}

moved {
  from = aws_iam_role_policy_attachment.open_webui_ssm
  to   = module.open_webui.aws_iam_role_policy_attachment.ssm
}

moved {
  from = aws_iam_instance_profile.open_webui
  to   = module.open_webui.aws_iam_instance_profile.this
}

moved {
  from = aws_iam_role_policy.open_webui_secrets_read
  to   = module.open_webui.aws_iam_role_policy.this["secrets-read"]
}

moved {
  from = aws_iam_role.ec2_ssm
  to   = module.llm.aws_iam_role.this
}

moved {
  from = aws_iam_role_policy_attachment.ec2_ssm
  to   = module.llm.aws_iam_role_policy_attachment.ssm
}

moved {
  from = aws_iam_instance_profile.ec2_ssm
  to   = module.llm.aws_iam_instance_profile.this
}

moved {
  from = aws_launch_template.llm
  to   = module.llm.aws_launch_template.this
}

moved {
  from = aws_autoscaling_group.llm
  to   = module.llm.aws_autoscaling_group.this
}

moved {
  from = aws_autoscaling_policy.cpu
  to   = module.llm.aws_autoscaling_policy.cpu
}

moved {
  from = aws_lb.llm
  to   = module.llm.aws_lb.this
}

moved {
  from = aws_lb_target_group.llm
  to   = module.llm.aws_lb_target_group.this
}

moved {
  from = aws_lb_listener.http
  to   = module.llm.aws_lb_listener.http
}

moved {
  from = aws_lb.web
  to   = module.web_alb.aws_lb.this
}

moved {
  from = aws_lb_listener.web_http
  to   = module.web_alb.aws_lb_listener.http
}

moved {
  from = aws_lb_listener.web_https
  to   = module.web_alb.aws_lb_listener.https
}

moved {
  from = aws_lb_target_group.grafana
  to   = module.web_alb.aws_lb_target_group.this["grafana"]
}

moved {
  from = aws_lb_target_group.open_webui
  to   = module.web_alb.aws_lb_target_group.this["open-webui"]
}

moved {
  from = aws_lb_target_group.keycloak
  to   = module.web_alb.aws_lb_target_group.this["keycloak"]
}

moved {
  from = aws_lb_target_group_attachment.grafana
  to   = module.web_alb.aws_lb_target_group_attachment.this["grafana"]
}

moved {
  from = aws_lb_target_group_attachment.open_webui
  to   = module.web_alb.aws_lb_target_group_attachment.this["open-webui"]
}

moved {
  from = aws_lb_target_group_attachment.keycloak
  to   = module.web_alb.aws_lb_target_group_attachment.this["keycloak"]
}

moved {
  from = aws_lb_listener_rule.grafana
  to   = module.web_alb.aws_lb_listener_rule.this["grafana"]
}

moved {
  from = aws_lb_listener_rule.open_webui
  to   = module.web_alb.aws_lb_listener_rule.this["open-webui"]
}

moved {
  from = aws_lb_listener_rule.keycloak
  to   = module.web_alb.aws_lb_listener_rule.this["keycloak"]
}

moved {
  from = aws_route53_record.grafana
  to   = module.web_alb.aws_route53_record.this["grafana"]
}

moved {
  from = aws_route53_record.open_webui
  to   = module.web_alb.aws_route53_record.this["open-webui"]
}

moved {
  from = aws_route53_record.keycloak
  to   = module.web_alb.aws_route53_record.this["keycloak"]
}
