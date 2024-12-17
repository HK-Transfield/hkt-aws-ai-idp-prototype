data "aws_region" "current" {}

resource "random_string" "this" {
  length  = 16
  special = false
  upper   = false
}

resource "aws_s3_bucket" "results" {
  bucket = "${var.results_bucket_name}-${random_string.this}"
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.results.id
  acl    = "private"
}

data "aws_sqs_queue" "current_queue" {
  name = var.sqs_queue_name
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_textract_processor_role"

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

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "textract:GetDocumentTextDetection",
          "bedrock:InvokeModel",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

locals {
  lambda_source  = "${path.module}/${var.lambda_function_name}.py"
  lambda_handler = "${var.lambda_function_name}.lambda_handler"
  lambda_zip     = "${var.lambda_function_name}.zip"
}

resource "aws_lambda_function" "sqs_processor_lambda" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.9"
  handler       = local.lambda_handler

  filename         = local.lambda_zip
  source_code_hash = filebase64sha256(local.lambda_zip)

  environment {
    variables = {
      RESULT_BUCKET = aws_s3_bucket.results.bucket
      TEXTRACT_ROLE = aws_iam_role.lambda_role.arn
    }
  }
}

# SQS event source mapping for Lambda
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.processing_queue.arn
  function_name    = aws_lambda_function.sqs_processor_lambda.arn
  batch_size       = 5
}

# Allow Lambda to write logs
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.sqs_processor_lambda.function_name}"
  retention_in_days = 14
}