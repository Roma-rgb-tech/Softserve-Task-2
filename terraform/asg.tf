resource "aws_launch_template" "llm" {
  name_prefix            = "${var.environment}-llm-"
  image_id               = data.aws_ami.ollama.id
  instance_type          = var.app_instance_type
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.app.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm.name
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

resource "aws_autoscaling_group" "llm" {
  name                      = "${var.environment}-llm-asg"
  vpc_zone_identifier       = module.network.private_subnet_ids
  min_size                  = 2
  max_size                  = 4
  desired_capacity          = 2
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.llm.id
    version = aws_launch_template.llm.latest_version
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
}


resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.environment}-llm-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.llm.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 60
  }
}
