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