#tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "web" {
  name                       = "${lower(var.environment)}-web-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.web_alb.id]
  subnets                    = module.network.public_subnet_ids
  drop_invalid_header_fields = true
  idle_timeout               = 300

  tags = {
    Name = "${var.environment}-web-alb"
  }
}

resource "aws_lb_target_group" "grafana" {
  name     = "${lower(var.environment)}-grafana-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = module.network.vpc_id

  health_check {
    path                = "/api/health"
    matcher             = "200"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group" "open_webui" {
  name     = "${lower(var.environment)}-open-webui-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.network.vpc_id

  health_check {
    path                = "/health"
    matcher             = "200"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group_attachment" "grafana" {
  target_group_arn = aws_lb_target_group.grafana.arn
  target_id        = aws_instance.monitoring.id
  port             = 3000
}

resource "aws_lb_target_group_attachment" "open_webui" {
  target_group_arn = aws_lb_target_group.open_webui.arn
  target_id        = aws_instance.open_webui.id
  port             = 8080
}

resource "aws_lb_listener" "web_http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "web_https" {
  load_balancer_arn = aws_lb.web.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.main.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "grafana" {
  listener_arn = aws_lb_listener.web_https.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }

  condition {
    host_header {
      values = ["grafana.${var.domain_name}"]
    }
  }
}

resource "aws_lb_listener_rule" "open_webui" {
  listener_arn = aws_lb_listener.web_https.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.open_webui.arn
  }

  condition {
    host_header {
      values = ["chat.${var.domain_name}"]
    }
  }
}
