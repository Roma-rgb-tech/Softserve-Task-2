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

data "aws_ami" "bastion" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:Role"
    values = ["bastion"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_ami" "monitoring" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:Role"
    values = ["monitoring"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_ami" "open_webui" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:Role"
    values = ["open-webui"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_ami" "keycloak" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:Role"
    values = ["keycloak"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
