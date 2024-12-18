/*
Name: Intelligent Document Processing on AWS
Author: HK Transifeld, 2024

This module deploys the resources needed to store
documents via S3. It upload documents to S3 to invoke 
a Lambda Function for processing documents.

Afterwards, it starts a Textract asynchronous job by 
using a Lambda function. The Lambda function is triggered by S3 events.
*/

data "aws_region" "current" {}

################################################################################
# SNS Topic & SQS Queue for Textract notifications
################################################################################

resource "aws_sns_topic" "textract_updates" {
  name = var.sns_topic_name
}

resource "aws_sqs_queue" "textract_updates" {
  name   = var.sqs_queue_name
  policy = aws_sqs_queue_policy.textract_policy.policy
}

resource "aws_sns_topic_subscription" "textract_updates_sqs_target" {
  topic_arn  = aws_sns_topic.textract_updates.arn
  protocol   = "sqs"
  endpoint   = aws_sqs_queue.textract_updates.arn
  depends_on = [aws_sqs_queue_policy.textract_policy]
}

resource "aws_sqs_queue_policy" "textract_policy" {
  queue_url = aws_sqs_queue.textract_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.textract_updates.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.textract_updates.arn
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "textract_sns" {
  name = "textract_sns_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "textract.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "textract_sns" {
  role = aws_iam_role.textract_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.textract_updates.arn
      }
    ]
  })
}
