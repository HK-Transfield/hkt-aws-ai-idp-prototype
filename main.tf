/*
Upload documents to Amazon S3 which will invoke an AWS Lambda Function for processing documents.
*/

resource "random_string" "this" {
  length  = 16
  special = false
  upper   = false
}

resource "aws_s3_bucket" "input_documents" {
  bucket = "hkt-input-documents-${random_string.this}"
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.input_documents.id
  acl    = "private"
}

/*
Start an Amazon Textract asynchronous job by using a Lambda function.
*/

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

resource "aws_lambda_function" "process_documents" {
  function_name = "process-documents"
  role          = aws_iam_role.lambda_role_textract_async_job.arn
  runtime       = "python3.9"
}
