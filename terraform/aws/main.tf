module "network" {
  source = "./modules/network"

  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  db_subnet_cidrs      = var.db_subnet_cidrs
  availability_zones   = var.availability_zones
  enable_nat_gateway   = var.enable_nat_gateway
  db_client_cidrs      = concat(var.private_subnet_cidrs, [var.public_subnet_cidrs[0]])
}

resource "aws_key_pair" "main" {
  key_name   = "${var.environment}-key"
  public_key = var.ssh_public_key
}

module "database" {
  source = "./modules/database"

  environment        = var.environment
  subnet_ids         = module.network.db_subnet_ids
  security_group_ids = [aws_security_group.db.id]
  instance_class     = var.db_instance_class
}

module "bastion" {
  source = "./modules/ec2"

  name               = "bastion"
  environment        = var.environment
  instance_type      = var.bastion_instance_type
  subnet_id          = module.network.public_subnet_ids[0]
  security_group_ids = [aws_security_group.bastion.id]
  key_name           = aws_key_pair.main.key_name
  root_volume_size   = 8
  user_data = templatefile("${path.module}/templates/alloy.sh.tftpl", {
    monitoring_ip = module.monitoring.private_ip
  })
}

#tfsec:ignore:aws-iam-no-policy-wildcards
module "monitoring" {
  source = "./modules/ec2"

  name               = "monitoring"
  environment        = var.environment
  instance_type      = var.monitoring_instance_type
  subnet_id          = module.network.public_subnet_ids[1]
  security_group_ids = [aws_security_group.monitoring.id]
  key_name           = aws_key_pair.main.key_name
  user_data = templatefile("${path.module}/templates/monitoring.sh.tftpl", {
    region                     = var.aws_region
    grafana_password_parameter = aws_ssm_parameter.grafana_admin_password.name
    grafana_root_url           = module.web_alb.urls["grafana"]
    slack_webhook_parameter    = aws_ssm_parameter.slack_webhook_url.name
    alertmanager_config = templatefile("${path.module}/templates/alertmanager.yml.tftpl", {
      topic_arn = aws_sns_topic.alerts.arn
      region    = var.aws_region
    })
  })

  policies = {
    cloudwatch-read = [
      {
        Sid    = "CloudWatchRead"
        Effect = "Allow"
        Action = [
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetInsightRuleReport",
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "tag:GetResources"
        ]
        Resource = "*"
      }
    ]
    grafana-secret-read = [
      {
        Sid      = "ReadGrafanaAdminPassword"
        Effect   = "Allow"
        Action   = "ssm:GetParameter"
        Resource = aws_ssm_parameter.grafana_admin_password.arn
      }
    ]
    sns-publish = [
      {
        Sid      = "PublishAlerts"
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.alerts.arn
      }
    ]
    slack-webhook-read = [
      {
        Sid      = "ReadSlackWebhook"
        Effect   = "Allow"
        Action   = "ssm:GetParameter"
        Resource = aws_ssm_parameter.slack_webhook_url.arn
      }
    ]
  }
}

module "keycloak" {
  source = "./modules/ec2"

  name               = "keycloak"
  environment        = var.environment
  instance_type      = var.keycloak_instance_type
  subnet_id          = module.network.private_subnet_ids[0]
  security_group_ids = [aws_security_group.keycloak.id]
  key_name           = aws_key_pair.main.key_name
  user_data = templatefile("${path.module}/templates/keycloak.sh.tftpl", {
    region                   = var.aws_region
    monitoring_ip            = module.monitoring.private_ip
    db_host                  = module.database.address
    db_name                  = module.database.db_name
    db_master_username       = module.database.username
    db_master_secret_arn     = module.database.master_user_secret_arn
    db_password_parameter    = aws_ssm_parameter.keycloak_db_password.name
    admin_password_parameter = aws_ssm_parameter.keycloak_admin_password.name
    hostname                 = "auth.${var.domain_name}"
  })

  policies = {
    secrets-read = [
      {
        Sid    = "ReadKeycloakParameters"
        Effect = "Allow"
        Action = "ssm:GetParameter"
        Resource = [
          aws_ssm_parameter.keycloak_admin_password.arn,
          aws_ssm_parameter.keycloak_db_password.arn
        ]
      },
      {
        Sid      = "ReadDatabaseMasterSecret"
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = module.database.master_user_secret_arn
      }
    ]
  }
}

module "open_webui" {
  source = "./modules/ec2"

  name               = "open-webui"
  environment        = var.environment
  instance_type      = var.open_webui_instance_type
  subnet_id          = module.network.public_subnet_ids[0]
  security_group_ids = [aws_security_group.open_webui.id]
  key_name           = aws_key_pair.main.key_name
  user_data = templatefile("${path.module}/templates/open-webui.sh.tftpl", {
    region                       = var.aws_region
    monitoring_ip                = module.monitoring.private_ip
    db_host                      = module.database.address
    db_name                      = module.database.db_name
    db_master_username           = module.database.username
    db_master_secret_arn         = module.database.master_user_secret_arn
    db_password_parameter        = aws_ssm_parameter.open_webui_db_password.name
    secret_key_parameter         = aws_ssm_parameter.open_webui_secret_key.name
    ollama_host                  = module.llm.alb_dns_name
    open_webui_url               = module.web_alb.urls["open-webui"]
    openid_provider_url          = "http://${module.keycloak.private_ip}:8080/realms/${var.keycloak_realm}/.well-known/openid-configuration"
    oidc_client_secret_parameter = aws_ssm_parameter.open_webui_oidc_client_secret.name
  })

  policies = {
    secrets-read = [
      {
        Sid    = "ReadOpenWebUIParameters"
        Effect = "Allow"
        Action = "ssm:GetParameter"
        Resource = [
          aws_ssm_parameter.open_webui_db_password.arn,
          aws_ssm_parameter.open_webui_secret_key.arn,
          aws_ssm_parameter.open_webui_oidc_client_secret.arn
        ]
      },
      {
        Sid      = "ReadDatabaseMasterSecret"
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = module.database.master_user_secret_arn
      }
    ]
  }
}

module "llm" {
  source = "./modules/llm"

  environment                 = var.environment
  vpc_id                      = module.network.vpc_id
  subnet_ids                  = module.network.private_subnet_ids
  instance_type               = var.app_instance_type
  key_name                    = aws_key_pair.main.key_name
  instance_security_group_ids = [aws_security_group.app.id]
  alb_security_group_ids      = [aws_security_group.alb.id]
  user_data = templatefile("${path.module}/templates/ollama.sh.tftpl", {
    monitoring_ip = module.monitoring.private_ip
    model         = "qwen2.5:3b"
    num_parallel  = var.ollama_num_parallel
    max_queue     = var.ollama_max_queue
    num_thread    = var.ollama_num_thread
  })
}

module "web_alb" {
  source = "./modules/web_alb"

  environment        = var.environment
  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [aws_security_group.web_alb.id]
  certificate_arn    = aws_acm_certificate_validation.main.certificate_arn
  zone_id            = aws_route53_zone.main.zone_id
  domain_name        = var.domain_name

  services = {
    grafana = {
      subdomain         = "grafana"
      port              = 3000
      priority          = 10
      health_check_path = "/api/health"
    }
    open-webui = {
      subdomain         = "chat"
      port              = 8080
      priority          = 20
      health_check_path = "/health"
    }
    keycloak = {
      subdomain         = "auth"
      port              = 8080
      priority          = 30
      health_check_path = "/health/ready"
      health_check_port = "9000"
    }
  }

  targets = {
    grafana    = module.monitoring.id
    open-webui = module.open_webui.id
    keycloak   = module.keycloak.id
  }
}
