terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    bucket       = "roma-tfstate-softserve-task1"
    key          = "task2/grafana/terraform.tfstate"
    region       = "eu-north-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}

data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "roma-tfstate-softserve-task1"
    key    = "task2/terraform.tfstate"
    region = "eu-north-1"
  }
}

data "aws_ssm_parameter" "grafana_admin_password" {
  name = data.terraform_remote_state.infra.outputs.grafana_admin_password_parameter
}

provider "grafana" {
  url  = data.terraform_remote_state.infra.outputs.grafana_url
  auth = "admin:${data.aws_ssm_parameter.grafana_admin_password.value}"
}
