resource "aws_route53_zone" "main" {
  name              = var.domain_name
  delegation_set_id = var.route53_delegation_set_id
  force_destroy     = true

  tags = {
    Name = "${var.environment}-zone"
  }
}
