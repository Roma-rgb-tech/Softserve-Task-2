variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "eu-north-1"
}

variable "environment" {
  description = "Environment name for naming and tagging"
  type        = string
  default     = "Dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the main VPC"
  type        = string
  default     = "10.0.0.0/24"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.0.0/27", "10.0.0.32/27"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private application subnets"
  type        = list(string)
  default     = ["10.0.0.64/27", "10.0.0.96/27"]
}

variable "db_subnet_cidrs" {
  description = "CIDR blocks for private database subnets"
  type        = list(string)
  default     = ["10.0.0.128/27", "10.0.0.160/27"]
}

variable "availability_zones" {
  description = "Availability zones for high availability deployment"
  type        = list(string)
  default     = ["eu-north-1a", "eu-north-1b"]
}

variable "enable_nat_gateway" {
  description = "Enable or disable NAT Gateway creation"
  type        = bool
  default     = true
}

variable "admin_cidr" {
  description = "Admin IP allowed to SSH into the bastion, in x.x.x.x/32 format"
  type        = string

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0)) && endswith(var.admin_cidr, "/32")
    error_message = "admin_cidr must be a single IP in /32 format."
  }
}

variable "ssh_public_key" {
  description = "Public SSH key for the bastion and private instances"
  type        = string
}

variable "bastion_instance_type" {
  description = "Instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

variable "app_instance_type" {
  description = "Instance type for LLM instances in the ASG"
  type        = string
  default     = "t3.small"
}

variable "db_instance_type" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_instance_class" {
  description = "RDS isntance type"
  type        = string
  default     = "db.t3.micro"
}
