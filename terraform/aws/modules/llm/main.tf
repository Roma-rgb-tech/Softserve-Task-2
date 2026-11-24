data "aws_ami" "ollama" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:Role"
    values = ["ollama"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_iam_role" "this" {
  name = "${var.environment}-llm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.environment}-llm-instance-profile"
  role = aws_iam_role.this.name
}

resource "aws_launch_template" "this" {
  name_prefix            = "${var.environment}-llm-"
  image_id               = data.aws_ami.ollama.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.instance_security_group_ids
  user_data              = base64encode(var.user_data)

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.environment}-llm"
    }
  }
}

resource "aws_autoscaling_group" "this" {
  name                      = "${var.environment}-llm-asg"
  vpc_zone_identifier       = var.subnet_ids
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  health_check_type         = "ELB"
  health_check_grace_period = 600
  target_group_arns         = [aws_lb_target_group.this.arn]
  enabled_metrics           = ["GroupInServiceInstances"]
  metrics_granularity       = "1Minute"

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-llm"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.environment}-llm-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = var.cpu_target
  }
}

locals {
  custom_scaling = {
    queue = {
      metric = "MessagesInQueue"
      label  = "Messages in queue per Ollama instance"
      target = var.queue_target
    }
    messages = {
      metric = "MessagesPerMinute"
      label  = "Chat messages per minute per Ollama instance"
      target = var.messages_target
    }
  }
}

resource "aws_autoscaling_policy" "custom" {
  for_each = local.custom_scaling

  name                   = "${var.environment}-llm-${each.key}-target"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    customized_metric_specification {
      metrics {
        id          = "value"
        return_data = false

        metric_stat {
          metric {
            namespace   = "LLM"
            metric_name = each.value.metric

            dimensions {
              name  = "Environment"
              value = var.environment
            }
          }

          stat = "Average"
        }
      }

      metrics {
        id          = "instances"
        return_data = false

        metric_stat {
          metric {
            namespace   = "AWS/AutoScaling"
            metric_name = "GroupInServiceInstances"

            dimensions {
              name  = "AutoScalingGroupName"
              value = aws_autoscaling_group.this.name
            }
          }

          stat = "Average"
        }
      }

      metrics {
        id          = "per_instance"
        expression  = "value / instances"
        label       = each.value.label
        return_data = true
      }
    }

    target_value = each.value.target
  }
}

resource "aws_lb" "this" {
  name                       = "${lower(var.environment)}-llm-alb"
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = var.alb_security_group_ids
  subnets                    = var.subnet_ids
  drop_invalid_header_fields = true
  idle_timeout               = 900

  tags = {
    Name = "${var.environment}-llm-alb"
  }
}

resource "aws_lb_target_group" "this" {
  name                          = "${lower(var.environment)}-llm-tg"
  port                          = 11434
  protocol                      = "HTTP"
  vpc_id                        = var.vpc_id
  load_balancing_algorithm_type = "least_outstanding_requests"

  health_check {
    path                = "/"
    matcher             = "200"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

#tfsec:ignore:aws-elb-http-not-used
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
