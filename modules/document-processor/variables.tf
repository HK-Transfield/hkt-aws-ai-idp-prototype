variable "input_bucket_name" {
  type    = string
  default = "hkt-input-documents"
}

variable "lambda_function_name" {
  type = string
}

variable "sns_topic_name" {
  type    = string
  default = "textract-completion-topic"
}

variable "sqs_queue_name" {
  type    = string
  default = "textract-completion-queue"
}

variable "runtime" {
  type    = string
  default = "python3.9"
}