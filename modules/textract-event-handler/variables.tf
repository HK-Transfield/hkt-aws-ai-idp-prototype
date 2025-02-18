/*
Name: Event Handler Module
Project:  AWS Generative AI Backed IDP Solution
Author: HK Transifeld, 2024
*/

variable "sns_topic_name" {
  type        = string
  description = "The SNS topic name"
}

variable "sqs_queue_name" {
  type        = string
  description = "The SQS queue name"
}

################################################################################
# Other configurations
################################################################################

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the resource"
}

