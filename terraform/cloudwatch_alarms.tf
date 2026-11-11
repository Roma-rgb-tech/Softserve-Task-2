locals {
  alarm_actions = [aws_sns_topic.alerts.arn]

  db_alarms = {
    cpu = {
      metric     = "CPUUtilization"
      comparison = "GreaterThanThreshold"
      threshold  = 80
    }
    memory = {
      metric     = "FreeableMemory"
      comparison = "LessThanThreshold"
      threshold  = 40 * 1024 * 1024
    }
    storage = {
      metric     = "FreeStorageSpace"
      comparison = "LessThanThreshold"
      threshold  = 2 * 1024 * 1024 * 1024
    }
  }

  elb_error_alarms = {
    "4XX-errors" = {
      metric    = "HTTPCode_Target_4XX_Count"
      threshold = 20
    }
    "5XX-errors" = {
      metric    = "HTTPCode_Target_5XX_Count"
      threshold = 5
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "db" {
  for_each = local.db_alarms

  alarm_name          = "[llm]-[test]-[db]-[high]-[${each.key}]"
  alarm_description   = "RDS ${each.value.metric} on ${aws_db_instance.postgres.identifier}"
  namespace           = "AWS/RDS"
  metric_name         = each.value.metric
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  comparison_operator = each.value.comparison
  threshold           = each.value.threshold
  treat_missing_data  = "missing"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.identifier
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "elb_host_count" {
  alarm_name          = "[llm]-[test]-[elb]-[high]-[host-count]"
  alarm_description   = "Healthy Ollama targets below ASG min size"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HealthyHostCount"
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 3
  comparison_operator = "LessThanThreshold"
  threshold           = aws_autoscaling_group.llm.min_size
  treat_missing_data  = "breaching"

  dimensions = {
    LoadBalancer = aws_lb.llm.arn_suffix
    TargetGroup  = aws_lb_target_group.llm.arn_suffix
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "elb_errors" {
  for_each = local.elb_error_alarms

  alarm_name          = "[llm]-[test]-[elb]-[medium]-[${each.key}]"
  alarm_description   = "ALB ${each.value.metric} above ${each.value.threshold} in 5 minutes"
  namespace           = "AWS/ApplicationELB"
  metric_name         = each.value.metric
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = each.value.threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.llm.arn_suffix
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}
