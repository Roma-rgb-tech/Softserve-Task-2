variable "environment" {
  type        = string
  description = "Environment name"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDR blocks"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDR blocks"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones list"
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Controls whether to create a NAt Gateway for private subnets"
  default     = true
}

variable "db_subnet_cidrs" {
  type        = list(string)
  description = "Database subnet CIDR blocks"
}
