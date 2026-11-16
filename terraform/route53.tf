resource "aws_route53_zone" "main" {
  name              = var.domain_name
  delegation_set_id = var.route53_delegation_set_id
  force_destroy     = true

  tags = {
    Name = "${var.environment}-zone"
  }
}

resource "aws_route53_record" "grafana" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "grafana.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.web.dns_name
    zone_id                = aws_lb.web.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "open_webui" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "chat.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.web.dns_name
    zone_id                = aws_lb.web.zone_id
    evaluate_target_health = true
  }
}
