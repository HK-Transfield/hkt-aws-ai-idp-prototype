variable "user_profile_name" {
  description = "The user profile name for the IDP workshop"
  type        = string
  default     = "SageMakerUser"
}

variable "domain_name" {
  description = "The domain name of the Sagemaker studio instance"
  type        = string
  default     = "IDPSagemakerDomain"
}

variable "region" {
  description = "The region name where to deploy the IDP"
  type        = string
  default     = "us-east-1"
}