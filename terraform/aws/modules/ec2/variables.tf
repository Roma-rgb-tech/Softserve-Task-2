variable "name" {
  description = "Server name, also used as the Role tag of its Packer AMI"
  type        = string
}

variable "environment" {
  description = "Environment name for naming and tagging"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "subnet_id" {
  description = "Subnet to launch the instance in"
  type        = string
}

variable "security_group_ids" {
  description = "Security groups attached to the instance"
  type        = list(string)
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "user_data" {
  description = "Rendered user data script"
  type        = string
}

variable "root_volume_size" {
  description = "Root volume size in GiB"
  type        = number
  default     = 20
}

variable "policies" {
  description = "Inline IAM policies for the instance role, as policy name to list of statements"
  type        = any
  default     = {}
}
