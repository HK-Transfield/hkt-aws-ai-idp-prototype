/*
Name: Lambda Function Builder
Author: HK Transifeld, 2024

This module configures the resources needed to set up 
any Lambda functions with the intended policies and
settings.

This module is intended to be used as a building block
for functions that perform the following tasks:
  - Document processing
  - Document classification
  - Document enrichment and extraction
  - Review and validation automation
*/

data "aws_region" "current" {}

################################################################################
# IAM Roles and Policy attachment for Lambda
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
  lambda_source  = "${path.root}/lambdas/${var.lambda_filename}/index.py"
  lambda_output  = "${path.root}/archives/${var.lambda_filename}.zip"
  lambda_handler = "${var.lambda_filename}.lambda_handler"
}

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
}
