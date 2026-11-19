resource "aws_instance" "keycloak" {
  ami                    = data.aws_ami.keycloak.id
  instance_type          = var.keycloak_instance_type
  subnet_id              = module.network.private_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.keycloak.id]
  key_name               = aws_key_pair.main.key_name
  iam_instance_profile   = aws_iam_instance_profile.keycloak.name
  user_data = templatefile("${path.module}/templates/keycloak.sh.tftpl", {
    region                   = var.aws_region
    monitoring_ip            = aws_instance.monitoring.private_ip
    db_host                  = aws_db_instance.postgres.address
    db_name                  = aws_db_instance.postgres.db_name
    db_master_username       = aws_db_instance.postgres.username
    db_master_secret_arn     = aws_db_instance.postgres.master_user_secret[0].secret_arn
    db_password_parameter    = aws_ssm_parameter.keycloak_db_password.name
    admin_password_parameter = aws_ssm_parameter.keycloak_admin_password.name
    hostname                 = "auth.${var.domain_name}"
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
    Name = "${var.environment}-keycloak"
  }
}
