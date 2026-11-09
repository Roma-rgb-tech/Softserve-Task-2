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
