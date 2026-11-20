output "urls" {
  value = { for name, record in aws_route53_record.this : name => "https://${record.fqdn}" }
}
