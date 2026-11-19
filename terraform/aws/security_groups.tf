resource "aws_security_group" "bastion" {
  name        = "${var.environment}-bastion-sg"
  description = "SSH access to bastion from admin IP only"
  vpc_id      = module.network.vpc_id

  ingress {
    description = "SSH from admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    description = "SSH to instances inside the VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Prometheus remote write to monitoring host"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${var.environment}-bastion-sg"
  }
}

resource "aws_security_group" "app" {
  name        = "${var.environment}-app-sg"
  description = "LLM instances in private subnets"
  vpc_id      = module.network.vpc_id

  ingress {
    description     = "SSH from bastion only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    description     = "Ollama API from ALB"
    from_port       = 11434
    to_port         = 11434
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Outbound internet via NAT for packages and models"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-app-sg"
  }
}

resource "aws_security_group" "db" {
  name        = "${var.environment}-db-sg"
  description = "PostgreSQL access from app instances only"
  vpc_id      = module.network.vpc_id

  ingress {
    description     = "PostgreSQL from app instances"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  ingress {
    description     = "PostgreSQL from Open WebUI"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.open_webui.id]
  }

  ingress {
    description     = "PostgreSQL from Keycloak"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.keycloak.id]
  }

  tags = {
    Name = "${var.environment}-db-sg"
  }
}

resource "aws_security_group" "monitoring" {
  name        = "${var.environment}-monitoring-sg"
  description = "Monitoring host with Grafana, Prometheus and Alertmanager"
  vpc_id      = module.network.vpc_id

  ingress {
    description     = "Grafana from public ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.web_alb.id]
  }

  ingress {
    description     = "SSH from bastion only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    description     = "Prometheus remote write from Alloy agents"
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id, aws_security_group.bastion.id, aws_security_group.open_webui.id, aws_security_group.keycloak.id]
  }

  egress {
    description = "Outbound for AWS APIs, Slack and packages"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-monitoring-sg"
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Internal ALB in front of Ollama"
  vpc_id      = module.network.vpc_id

  ingress {
    description     = "HTTP from Open WebUI"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.open_webui.id]
  }

  egress {
    description = "Ollama API on LLM instances"
    from_port   = 11434
    to_port     = 11434
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  tags = {
    Name = "${var.environment}-alb-sg"
  }
}

resource "aws_security_group" "open_webui" {
  name        = "${var.environment}-open-webui-sg"
  description = "Open WebUI host"
  vpc_id      = module.network.vpc_id

  ingress {
    description     = "Open WebUI from public ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web_alb.id]
  }

  ingress {
    description     = "SSH from bastion only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    description = "Outbound for AWS APIs, RDS, ALB and Prometheus"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-open-webui-sg"
  }
}

resource "aws_security_group" "web_alb" {
  name        = "${var.environment}-web-alb-sg"
  description = "Public ALB in front of Grafana and Open WebUI"
  vpc_id      = module.network.vpc_id

  ingress {
    description = "HTTP from internet for redirect to HTTPS"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.vpn_cidrs
  }

  ingress {
    description = "HTTPS from corporate VPN"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.vpn_cidrs
  }

  egress {
    description = "Grafana on monitoring host"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.public_subnet_cidrs
  }

  egress {
    description = "Open WebUI host"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.public_subnet_cidrs
  }

  egress {
    description = "Keycloak in private subnets"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  egress {
    description = "Keycloak management port for health checks"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  tags = {
    Name = "${var.environment}-web-alb-sg"
  }
}

resource "aws_security_group" "keycloak" {
  name        = "${var.environment}-keycloak-sg"
  description = "Keycloak behind public ALB"
  vpc_id      = module.network.vpc_id

  ingress {
    description     = "Keycloak HTTP from public ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web_alb.id]
  }

  ingress {
    description = "Keycloak backchannel from Grafana and Open WebUI hosts"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.public_subnet_cidrs
  }
  ingress {
    description     = "Keycloak health checks from public ALB"
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.web_alb.id]
  }

  ingress {
    description     = "SSH from bastion only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    description = "Outbound for RDS, AWS APIs, Identity providers and Prometheus"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-keycloak-sg"
  }
}
