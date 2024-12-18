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

resource "aws_sns_topic" "this" {
  name = var.sns_topic_name
}

resource "aws_sqs_queue" "this" {
  name = var.sqs_queue_name
}

resource "aws_sns_topic_subscription" "this" {
  topic_arn  = aws_sns_topic.this.arn
  protocol   = "sqs"
  endpoint   = aws_sqs_queue.this.arn
  depends_on = [aws_sqs_queue_policy.this]
}

data "aws_iam_policy_document" "this" {
  statement {
    sid    = "SQSSendMessage"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.this.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.this.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "this" {
  queue_url = aws_sqs_queue.this.id
  policy    = data.aws_iam_policy_document.this.json
}

resource "aws_iam_role" "this" {
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

resource "aws_iam_role_policy" "this" {
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.this.arn
      }
    ]
  })
}
