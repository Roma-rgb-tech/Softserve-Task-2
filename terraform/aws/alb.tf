resource "aws_lb" "llm" {
  name                       = "${lower(var.environment)}-llm-alb"
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = module.network.private_subnet_ids
  drop_invalid_header_fields = true
  idle_timeout               = 300

  tags = {
    Name = "${var.environment}-llm-alb"
  }
}

resource "aws_lb_target_group" "llm" {
  name     = "${lower(var.environment)}-llm-tg"
  port     = 11434
  protocol = "HTTP"
  vpc_id   = module.network.vpc_id

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
  load_balancer_arn = aws_lb.llm.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.llm.arn
  }
}
