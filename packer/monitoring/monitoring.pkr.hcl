packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.8"
    }
  }
}

variable "region" {
  type    = string
  default = "eu-north-1"
}

variable "build_version" {
  type    = string
  default = "1.0.0"
}

variable "open_webui_version" {
  type = string
  default = "v0.13.3"
}

variable "git_commit" {
  type    = string
  default = "local"
}

locals {
  timestamp = formatdate("YYYYMMDD-hhmm", timestamp())
}

source "amazon-ebs" "monitoring" {
  region        = var.region
  instance_type = "t3.small"
  ssh_username  = "ubuntu"
  ami_name      = "monitoring-${var.build_version}-${local.timestamp}"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-resolute-26.04-amd64-server-*"
      virtualization-type = "hvm"
      root-device-type    = "ebs"
    }
    owners      = ["099720109477"]
    most_recent = true
  }

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  encrypt_boot = true
  imds_support = "v2.0"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  temporary_security_group_source_public_ip = true

  run_tags = {
    Name = "packer-builder-monitoring"
  }

  tags = {
    Name         = "monitoring-${var.build_version}"
    Role         = "monitoring"
    Project      = "OCG1-Onborading"
    Environment  = "Task2"
    ManagedBy    = "Packer"
    BuildVersion = var.build_version
    BuildDate    = local.timestamp
    GitCommit    = var.git_commit
    OpenWebUI    = var.open_webui_version
    BaseAMI      = "{{ .SourceAMI}}"
    BaseAMIName  = "{{ .SourceAMIName}}"
  }
}

build {
  sources = ["source.amazon-ebs.monitoring"]

  provisioner "file" {
    sources     = ["config.alloy", "prometheus", "alertmanager", "open-webui.service"]
    destination = "/tmp/"
  }

  provisioner "shell" {
    script          = "setup.sh"
    environment_vars = ["OPEN_WEBUI_VERSION=${var.open_webui_version}"]
    execute_command = "sudo {{ .Vars }} bash '{{ .Path }}'"
  }

  post-processor "manifest" {
    output = "manifest.json"
  }
}
