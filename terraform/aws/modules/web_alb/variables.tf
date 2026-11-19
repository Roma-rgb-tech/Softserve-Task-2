variable "environment" {
  description = "Environment name for naming and tagging"
  type        = string
}

variable "vpc_id" {
  description = "VPC for the target groups"
  type        = string
}

variable "subnet_ids" {
  description = "Public subnets for the load balancer"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups attached to the load balancer"
  type        = list(string)
}

variable "certificate_arn" {
  description = "ACM certificate for the HTTPS listener"
  type        = string
}

variable "zone_id" {
  description = "Route53 hosted zone for the service records"
  type        = string
}

variable "domain_name" {
  description = "Domain the service subdomains belong to"
  type        = string
}

variable "services" {
  description = "Services behind the load balancer, keyed by service name"
  type = map(object({
    subdomain         = string
    port              = number
    priority          = number
    health_check_path = string
    health_check_port = optional(string, "traffic-port")
  }))
}

variable "targets" {
  description = "Instance ID behind each service, keyed by service name"
  type        = map(string)
}
