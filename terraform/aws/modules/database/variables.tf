variable "environment" {
  description = "Environment name for naming and tagging"
  type        = string
}

variable "subnet_ids" {
  description = "Database subnets"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups attached to the database"
  type        = list(string)
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "db_name" {
  description = "Name of the initial database"
  type        = string
  default     = "llmdb"
}

variable "username" {
  description = "Master username"
  type        = string
  default     = "llm_admin"
}
