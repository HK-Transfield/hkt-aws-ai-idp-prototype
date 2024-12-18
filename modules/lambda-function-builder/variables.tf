################################################################################
# Lambda function configurations
################################################################################

variable "lambda_role_name" {
  type        = string
  description = "The name of the Lambda function role to attach"
}

variable "lambda_function_name" {
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

variable "iam_policy_name" {
  type        = string
  description = "The name of the IAM policy to attach the Lambda function role"
  default     = ""
}

variable "iam_policy_json" {
  type        = string
  description = "The rendered JSON policy document to be attached to the IAM policy"
}
