/*
Name: AWS AI IDP Prototype
Author: Harmon Transfield

This project provides a Terraform configuration for deploying an 
Intelligent Document Processing (IDP) solution in an AWS environment. 
The purpose of an IDP solution is to reduce the overall costs 
associated with typical document workflows.

The architecture for this project is based on the architecture diagram
provided by the AWS Solutions

At a high level, the solution performs the following functions:
  - Documents are uploaded to a storage bucket, triggering an asynchronous Amazon Textract detection job. 
  - Extracted text is classified and enriched using artificial intelligence and machine learning (AI/ML). 
  - Results are stored in the storage bucket. 
  - Automated validation and review steps.
  - Human review facilitated through Amazon Augmented AI (A2I) when necessary. 
  - Verified data is stored in a fully managed NoSQL database service and available for downstream applications.
*/

resource "random_string" "this" {
  length  = 16
  special = false
  upper   = false
}

################################################################################
# Document and Data Storage
################################################################################

# For uploading raw input documents 
resource "aws_s3_bucket" "input_documents" {
  bucket = "hkt-idp-input-documents-${random_string.this}"
}

resource "aws_s3_bucket_acl" "input_documents" {
  bucket = aws_s3_bucket.input_documents.id
  acl    = "private"
}

# For saving the classification prompt results 
resource "aws_s3_bucket" "classified_documents" {
  bucket = "hkt-idp-classified-documents-${random_string.this}"
}

resource "aws_s3_bucket_acl" "classified_documents" {
  bucket = aws_s3_bucket.input_documents.id
  acl    = "private"
}

# For any documents enriched by Amazon Bedrock
resource "aws_s3_bucket" "enriched_documents" {
  bucket = "hkt-idp-enriched-documents-${random_string.this}"
}

resource "aws_s3_bucket_acl" "enriched_documents" {
  bucket = aws_s3_bucket.enriched_documents.id
  acl    = "private"
}

################################################################################
# Allow Lambda to start a Textract async detection job
################################################################################

data "aws_iam_policy_document" "allow_lambda_textract_async_job" {
  statement {
    sid    = "EnableCloudWatchLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    sid    = "AllowTextractAsynchronousDetectionJobs"
    effect = "Allow"

    actions = [
      "textract:StartDocumentTextDetection",
      "textract:GetDocumentTextDetection",
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.input_documents.arn}/*"]
  }
}

module "document_processor" {
  source = "./modules/lambda-function-builder"

  lambda_role_name     = "DocumentProcessor"
  lambda_function_name = "hkt-idp-document-processor"

  environment_variables = {
    BUCKET_NAME       = aws_s3_bucket.input_documents.bucket
    SNS_TOPIC_ARN     = aws_sns_topic.textract_updates.arn
    TEXTRACT_ROLE_ARN = aws_iam_role.textract_sns.arn
  }

  iam_policy_json = data.aws_iam_policy_document.allow_lambda_textract_async_job.json
}

module "textract_update_handler" {
  source = "./modules/textract-update-handler"

  sns_topic_name = "hkt-idp-textract-completion-topic"
  sqs_queue_name = "hkt-idp-textract-completion-queue"
}

################################################################################
# Allow Lambda to get SQS queue triggers and read Textract output
################################################################################

data "aws_iam_policy_document" "allow_lambda_classify_documents" {
  statement {
    sid    = "ProcessClassifiedDocuments"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "textract:GetDocumentTextDetection",
      "bedrock:InvokeModel",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

################################################################################
# Allow Lambda to process document content according to the classification
################################################################################

data "aws_iam_policy_document" "allow_lambda_enrich_documents" {
  statement {
    sid    = "EnableCloudWatchLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    sid    = "SaveEnrichedDocumentsToS3"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.enriched_documents.arn}/*"]
  }

  statement {
    sid    = "InvokeBedrockModel"
    effect = "Allow"

    actions   = ["bedrock:InvokeModel"]
    resources = ["*"]
  }
}