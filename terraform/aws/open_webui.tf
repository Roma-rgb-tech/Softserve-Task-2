resource "aws_instance" "open_webui" {
  ami                    = data.aws_ami.open_webui.id
  instance_type          = var.open_webui_instance_type
  subnet_id              = module.network.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.open_webui.id]
  key_name               = aws_key_pair.main.key_name
  iam_instance_profile   = aws_iam_instance_profile.open_webui.name
  user_data = templatefile("${path.module}/templates/open-webui.sh.tftpl", {
    region                       = var.aws_region
    monitoring_ip                = aws_instance.monitoring.private_ip
    db_host                      = aws_db_instance.postgres.address
    db_name                      = aws_db_instance.postgres.db_name
    db_master_username           = aws_db_instance.postgres.username
    db_master_secret_arn         = aws_db_instance.postgres.master_user_secret[0].secret_arn
    db_password_parameter        = aws_ssm_parameter.open_webui_db_password.name
    secret_key_parameter         = aws_ssm_parameter.open_webui_secret_key.name
    ollama_host                  = aws_lb.llm.dns_name
    open_webui_url               = "https://${aws_route53_record.open_webui.fqdn}"
    openid_provider_url          = "http://${aws_instance.keycloak.private_ip}:8080/realms/${var.keycloak_realm}/.well-known/openid-configuration"
    oidc_client_secret_parameter = aws_ssm_parameter.open_webui_oidc_client_secret.name
  })
  user_data_replace_on_change = true

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${var.environment}-open-webui"
  }
}
