variable "results_bucket_name" {
  type    = string
  default = "hkt-results-documents"
}

variable "lambda_function_name" {
  type = string
}

variable "sqs_queue_name" {
  type = string
}
