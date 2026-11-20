variable "environment" {
  description = "Environment name for naming and tagging"
  type        = string
}

variable "vpc_id" {
  description = "VPC for the internal load balancer target group"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets for the load balancer and the Ollama instances"
  type        = list(string)
}

variable "instance_type" {
  description = "Instance type for Ollama instances"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "instance_security_group_ids" {
  description = "Security groups attached to Ollama instances"
  type        = list(string)
}

variable "alb_security_group_ids" {
  description = "Security groups attached to the internal load balancer"
  type        = list(string)
}

variable "user_data" {
  description = "Rendered user data script"
  type        = string
}

variable "min_size" {
  description = "Minimum number of Ollama instances"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of Ollama instances"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Desired number of Ollama instances"
  type        = number
  default     = 2
}

variable "cpu_target" {
  description = "Average CPU utilization the Auto Scaling Group keeps"
  type        = number
  default     = 60
}
