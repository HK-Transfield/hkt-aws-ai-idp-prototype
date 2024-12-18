/*
Name: AWS Lambda Function Builder
Author: HK Transifeld, 2024

This module deploys the resources needed to set up 
any Lambda functions for the IDP.
*/

data "aws_region" "current" {}

################################################################################
# IAM Roles and Policy attachment for Lambda
################################################################################

resource "aws_iam_role" "this" {
  name = var.lambda_role_name

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
}

resource "aws_iam_policy" "this" {
  name   = var.iam_policy_name
  policy = var.iam_policy_json
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

################################################################################
# Lambda function configuration
################################################################################

locals {
  lambda_source  = "${path.module}/${var.lambda_function_name}.py"
  lambda_handler = "${var.lambda_function_name}.lambda_handler"
  lambda_zip     = "${var.lambda_function_name}.zip"
}

resource "aws_lambda_function" "sqs_processor_lambda" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_role.arn
  runtime       = var.lambda_function_runtime
  handler       = local.lambda_handler

  filename         = local.lambda_zip
  source_code_hash = filebase64sha256(local.lambda_zip)

  environment {
    variables = var.environment_variables
  }
}
