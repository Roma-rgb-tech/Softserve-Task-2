#tfsec:ignore:aws-sns-topic-encryption-use-cmk
resource "aws_sns_topic" "alerts" {
  name              = "${lower(var.environment)}-llm-alerts"
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
