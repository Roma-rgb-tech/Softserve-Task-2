resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.monitoring.id
  instance_type          = var.monitoring_instance_type
  subnet_id              = module.network.public_subnet_ids[1]
  vpc_security_group_ids = [aws_security_group.monitoring.id]
  key_name               = aws_key_pair.main.key_name
  iam_instance_profile   = aws_iam_instance_profile.monitoring.name
  user_data = templatefile("${path.module}/templates/grafana.sh.tftpl", {
    region         = var.aws_region
    parameter_name = aws_ssm_parameter.grafana_admin_password.name
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
    Name = "${var.environment}-monitoring"
  }
}
