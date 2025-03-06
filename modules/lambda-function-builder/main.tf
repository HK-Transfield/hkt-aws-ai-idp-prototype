/*
Name:     Lambda Function Builder Module
Project:  AWS Generative AI Backed IDP Solution
Author:   HK Transfield, 2024

This module acts as a building block for configuring Lambda functions, along 
with their associated IAM roles and policies.
*/

data "aws_region" "current" {}

################################################################################
# IAM role and policy configuration
################################################################################

resource "aws_iam_role" "this" {
  name = var.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      "Name" = var.iam_role_name
    },
  )
}

resource "aws_iam_policy" "this" {
  name   = var.iam_policy_name
  policy = var.iam_policy_json

  tags = merge(
    var.tags,
    {
      "Name" = var.iam_policy_name
    },
  )
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

################################################################################
# Lambda function configuration
################################################################################

locals {
  lambda_source  = "${path.root}/lambdas/${var.lambda_filename}/index.py"
  lambda_output  = "${path.root}/archives/${var.lambda_filename}.zip"
  lambda_handler = "${var.lambda_filename}.lambda_handler"
}

# locally archive the lambda source code
data "archive_file" "this" {
  type        = "zip"
  source_file = local.lambda_source
  output_path = local.lambda_output
}

resource "aws_lambda_function" "this" {
  function_name = var.lambda_filename
  role          = aws_iam_role.this.arn
  runtime       = var.lambda_function_runtime
  handler       = local.lambda_handler

  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256

  environment {
    variables = var.environment_variables
  }

  tags = merge(
    var.tags,
    {
      "Name" = var.lambda_filename
    },
  )

  tracing_config {
    mode = "Active"
  }

  publish    = true
  depends_on = [aws_cloudwatch_log_group.this]
}

resource "aws_lambda_alias" "this" {
  name             = "latest"
  function_name    = aws_lambda_function.this.function_name
  function_version = "$LATEST"
}

################################################################################
# CloudWatch logging and monitoring configuration
################################################################################

locals {
  cloudwatch_log_group_name    = "${var.lambda_filename}-log-group"
  cloudwatch_metric_alarm_name = "${var.lambda_filename}-error-metric-alarm"
  sns_topic_name               = "${var.lambda_filename}-error-topic"
}

resource "aws_sns_topic" "lambda_error" {
  name = local.sns_topic_name

  tags = merge(
    var.tags,
    {
      "Name" = local.sns_topic_name
    },
  )
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.lambda_filename}"
  retention_in_days = var.cloudwatch_log_retention_in_days

  tags = merge(
    var.tags,
    {
      "Name" = local.cloudwatch_log_group_name
    },
  )
}

resource "aws_cloudwatch_metric_alarm" "this" {
  alarm_name          = local.cloudwatch_metric_alarm_name
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Triggers when the ${var.lambda_filename} Lambda function has errors."
  alarm_actions       = [aws_sns_topic.lambda_error.arn]

  dimensions = {
    FunctionName = aws_lambda_function.this.function_name
  }
}