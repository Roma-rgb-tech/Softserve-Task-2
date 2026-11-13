resource "aws_route53_zone" "main" {
  name          = var.domain_name
  force_destroy = true

  tags = {
    Name = "${var.environment}-zone"
  }
}

resource "aws_route53_record" "grafana" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "grafana.${var.domain_name}"
  type    = "A"
  ttl     = 60
  records = [aws_instance.monitoring.public_ip]
}

resource "aws_route53_record" "open_webui" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "chat.${var.domain_name}"
  type    = "A"
  ttl     = 60
  records = [aws_instance.open_webui.public_ip]
}
