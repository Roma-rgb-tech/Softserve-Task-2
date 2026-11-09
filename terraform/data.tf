data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-resolute-26.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

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
