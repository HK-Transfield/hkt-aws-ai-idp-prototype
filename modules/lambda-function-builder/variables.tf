/*
Name:     Lambda Function Builder Module
Project:  AWS Generative AI Backed IDP Solution
Author:   HK Transfield, 2024
*/

################################################################################
# Lambda function configurations
################################################################################

variable "lambda_filename" {
  type        = string
  description = "The name of the Lambda function being deployed"
}

variable "lambda_function_runtime" {
  type        = string
  description = "The language specific environment to relay invocation events, context information, and responses."
  default     = "python3.9"
}

variable "environment_variables" {
  type        = map(string)
  description = "Information about the function or runtime set during initialisation"
}

################################################################################
# IAM resource configurations
################################################################################

variable "iam_role_name" {
  type        = string
  description = "The name of the Lambda function role to attach"
}

variable "iam_policy_name" {
  type        = string
  description = "The name of the IAM policy to attach the Lambda function role"
}

variable "iam_policy_json" {
  type        = string
  description = "The rendered JSON policy document to be attached to the IAM policy"
}

################################################################################
# Storage configurations
################################################################################

# ? I can't remember the original plan for this variable
# variable "s3_bucket_name" {
#   type        = string
#   description = "The name of the S3 bucket to store the Lambda function zip file"
# }

################################################################################
# Logging and Monitoring configurations
################################################################################

variable "cloudwatch_log_retention_in_days" {
  type        = number
  description = "The number of days to retain the log events in the log group"
}

################################################################################
# Other configurations
################################################################################

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the resource"
}
