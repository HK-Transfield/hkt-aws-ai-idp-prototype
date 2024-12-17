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
# Document Storage
################################################################################

resource "random_string" "this" {
  length  = 16
  special = false
  upper   = false
}

resource "aws_s3_bucket" "input_documents" {
  bucket = "${var.input_bucket_name}-${random_string.this}"
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.input_documents.id
  acl    = "private"
}

################################################################################
# Lambda Role for Textract
################################################################################

resource "aws_iam_role" "lambda_role_textract_async_job" {
  name = "lambda-role-textract-async-job"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "lambda_role_textract_async_job" {
  name = "lambda-role-textract-async-job"
  policy = jsondecode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "textract:StartDocumentTextDetection",
          "textract:GetDocumentTextDetection",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.input_documents.arn}/*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_role_textract_async_job" {
  role       = aws_iam_role.lambda_role_textract_async_job.name
  policy_arn = aws_iam_policy.lambda_role_textract_async_job.arn
}

locals {
  lambda_source  = "${path.module}/${var.lambda_function_name}.py"
  lambda_handler = "${var.lambda_function_name}.lambda_handler"
  lambda_zip     = "${var.lambda_function_name}.zip"
}

data "local_file" "lambda_source" {
  filename = local.lambda_source
}

resource "aws_lambda_function" "process_documents" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_role_textract_async_job.arn
  runtime       = var.runtime
  handler       = local.lambda_handler
  filename      = local.lambda_zip

  environment {
    variables = {
      BUCKET_NAME       = aws_s3_bucket.input_documents.bucket
      SNS_TOPIC_ARN     = aws_sns_topic.textract_updates.arn
      TEXTRACT_ROLE_ARN = aws_iam_role.textract_sns.arn
    }
  }
}

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
