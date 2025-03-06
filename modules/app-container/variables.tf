variable "app_name" {
  description = "Name of the Streamlit application"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ECS service"
  type        = list(string)
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 8501
}

variable "cpu" {
  description = "CPU units for the ECS task"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory for the ECS task in MiB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of tasks running"
  type        = number
  default     = 1
}

variable "docker_image" {
  description = "Docker image for the Streamlit application"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket to store the documents"
  type        = string

}

variable "allowed_ingress_ip" {
  description = "List of allowed IPs to access the Streamlit application"
  type        = string
  default     = "0.0.0.0/0"
}

variable "allowed_egress_ip" {
  description = "List of allowed IPs to access the Streamlit application"
  type        = string
  default     = "0.0.0.0/0"
}

variable "min_capacity" {
  description = "Minimum capacity for the ECS service"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum capacity for the ECS service"
  type        = number
  default     = 3
}

variable "retention_in_days" {
  description = "Retention period for the CloudWatch logs"
  type        = number
  default     = 7
}

variable "alb_target_group_arn" {
  description = "ARN of the target group for the ECS service"
  type        = string
}

################################################################################
# Other configurations
################################################################################

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the resource"
}
