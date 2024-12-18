data "aws_region" "current" {}

data "aws_s3_bucket" "results" {
  bucket = var.results_bucket_name
}

resource "aws_iam_role" "lambda_enrichment" {
  name = "lambda_enrichment_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "lambda.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_enrichment" {
  role = aws_iam_role.lambda_enrichment.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:PutObject"],
        Resource = ["${data.aws_s3_bucket.results_bucket.arn}/*"]
      },
      {
        Effect   = "Allow",
        Action   = "bedrock:InvokeModel",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

# Lambda function to process S3 object
resource "aws_lambda_function" "enrichment_lambda" {
  function_name = "s3-document-enrichment"
  role          = aws_iam_role.lambda_enrichment_role.arn
  runtime       = "python3.9"
  handler       = "lambda_function.lambda_handler"

  filename         = "lambda_enrichment.zip"
  source_code_hash = filebase64sha256("lambda_enrichment.zip")

  environment {
    variables = {
      RESULT_BUCKET = data.aws_s3_bucket.results_bucket.bucket
    }
  }
}

# S3 bucket notification to trigger Lambda function
resource "aws_s3_bucket_notification" "lambda_trigger" {
  bucket = data.aws_s3_bucket.results_bucket.bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.enrichment_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".json" # Only process classification result files
  }

  depends_on = [aws_lambda_permission.s3]
}

# Allow S3 to invoke the Lambda function
resource "aws_lambda_permission" "s3" {
  statement_id  = "AllowS3Invocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.enrichment_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_s3_bucket.results_bucket.arn
}