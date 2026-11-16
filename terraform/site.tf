resource "aws_instance" "site" {
  ami                    = data.aws_ami.site.id
  instance_type          = var.site_instance_type
  subnet_id              = module.network.public_subnet_ids[1]
  vpc_security_group_ids = [aws_security_group.site.id]
  key_name               = aws_key_pair.main.key_name
  user_data = templatefile("${path.module}/templates/alloy.sh.tftpl", {
    monitoring_ip = aws_instance.monitoring.private_ip
  })
  user_data_replace_on_change = true

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${var.environment}-site"
  }
}
