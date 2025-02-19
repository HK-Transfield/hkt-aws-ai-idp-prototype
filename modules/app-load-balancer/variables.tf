variable "vpc_id" {
  description = "VPC ID where ALB will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ALB"
  type        = list(string)
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "allowed_ingress_ips" {
  description = "List of allowed IPs to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_egress_ips" {
  description = "List of allowed IPs to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "domain_name" {
  description = "Domain name for the ACM certificate"
  type        = string
}

################################################################################
# Other configurations
################################################################################

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the resource"
}
