/*
Name:     Root Module
Project:  AWS Generative AI Backed IDP Solution
Author:   HK Transfield, 2024

This configuration deploys an Intelligent Document Processing (IDP) solution 
within in an AWS environment. The goal of an IDP solution is to reduce the 
overall costs associated with typical document workflows.
*/

provider "aws" {
  region = "us-east-1"
}

locals {
  project_org  = "hkt"
  project_tag  = "idp"
  project_name = "${local.project_org}-${local.project_tag}"
}

locals {
  lambda_filenames = {
    "1-start-textract-async-detection-job"       = "start-textract-async-detection-job.zip"
    "2-classify-textract-output"                 = "classify-textract-output.zip"
    "3-entity-extraction-and-content-enrichment" = "entity-extraction-and-content-enrichment.zip"
    "4-results-validation"                       = "results-validation.zip"
    "5-human-review-and-validation"              = "human-review-and-validation.zip"
  }
}

################################################################################
# DOCUMENT INGESTION AND TEXT EXTRACTION
################################################################################

locals {
  updates_name                   = "${local.project_name}-textract-job"
  captured_documents_bucket_name = "${local.project_name}-captured-documents"
}

# capture data into an S3 bucket to trigger the following Lambda function
module "captured_documents_bucket" {
  source = "../modules/document-storage"

  bucket_name   = local.captured_documents_bucket_name
  force_destroy = true
}

# allow lambda to start textract jobs and access the captured documents bucket
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
    resources = ["${module.captured_documents_bucket.bucket_arn}/*"]
  }
}

# Start Textract async detection job
module "textract_events_lambda_function" {
  source = "../modules/lambda-function-builder"

  lambda_filename = "1-start-textract-async-detection-job"

  environment_variables = {
    SNS_TOPIC_ARN = module.textract_events.sns_topic_arn
    SNS_ROLE_ARN  = module.textract_events.sns_iam_role_arn
  }

  iam_role_name   = "AllowLambdaTextractAsyncJob"
  iam_policy_name = "AllowLambdaTextractAsyncJob"
  iam_policy_json = data.aws_iam_policy_document.allow_lambda_textract_async_job.json
}

module "textract_events" {
  source = "../modules/textract-event-handler"

  sns_topic_name = "${local.updates_name}-topic"
  sqs_queue_name = "${local.updates_name}-queue"
}

################################################################################
# DOCUMENT CLASSIFICATION
################################################################################

locals {
  classified_documents_bucket_name = "${local.project_name}-classified-documents"
  classified_documents_object_key  = "classified-results"
  bedrock_model_id                 = "anthropic.claude-3-sonnet-20240229-v1:0"
}

resource "aws_lambda_event_source_mapping" "textract_output" {
  event_source_arn = module.textract_events.sqs_queue_arn
  function_name    = module.textract_events_lambda_.function_arn
  batch_size       = 10
}

# allow lambda access to the SQS, Textract, and Bedrock API
data "aws_iam_policy_document" "allow_lambda_classify_documents" {
  statement {
    sid    = "InvokeLambdaFunction"
    effect = "Allow"

    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [module.textract_events.sqs_queue_arn]
  }

  statement {
    sid    = "ReadTextractOutput"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]
    resources = ["${module.classified_documents_bucket.bucket_arn}/*"]
  }

  statement {
    sid    = "InvokeBedrockModel"
    effect = "Allow"

    actions = [
      "bedrock:InvokeModel"
    ]
    resources = ["*"]
  }
}

# Start Bedrock classification job
module "classify_textract_output_lambda_function" {
  source = "../modules/lambda-function-builder"

  lambda_filename = "2a-classify-textract-output-bedrock"

  environment_variables = {
    OUTPUT_BUCKET     = aws_s3_bucket.classified_documents_bucket.bucket
    OUTPUT_OBJECT_KEY = local.classified_documents_object_key
    BEDROCK_MODEL_ID  = local.bedrock_model_id
  }

  iam_role_name   = "AllowLambdaClassifyDocuments"
  iam_policy_name = "AllowLambdaClassifyDocuments"
  iam_policy_json = data.aws_iam_policy_document.allow_lambda_classify_documents.json
}

module "classified_documents_bucket" {
  source = "../modules/document-storage"

  bucket_name   = local.classified_documents_bucket_name
  force_destroy = true
}

################################################################################
# ENTITY EXTRACTION AND CONTENT ENRICHMENT
################################################################################

# allow lambda access to the SQS, Textract, and Bedrock API
data "aws_iam_policy_document" "allow_lambda_enrich_content" {
  statement {
    sid    = "ReadTextractOutput"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]
    resources = ["${module.classified_documents_bucket.bucket_arn}/*"]
  }

  statement {
    sid    = "InvokeBedrockModel"
    effect = "Allow"

    actions = [
      "bedrock:InvokeModel"
    ]
    resources = ["*"]
  }
}

module "entity_extraction_and_content_enrichment_lambda_function" {
  source = "../modules/lambda-function-builder"

  lambda_filename = "3-entity-extraction-and-content-enrichment"

  environment_variables = {
    TARGET_BUCKET           = aws_s3_bucket.enriched_documents_bucket.bucket
    CLASSIFIED_DOCS_OBJ_KEY = local.classified_documents_object_key
  }

  iam_role_name   = "AllowLambdaEnrichDocumentContent"
  iam_policy_name = "AllowLambdaEnrichDocumentContent"
  iam_policy_json = data.aws_iam_policy_document.allow_lambda_enrich_content.json
}

################################################################################
# RESULTS VALIDATION
################################################################################

locals {
  validated_documents_bucket_name = "${local.project_name}-validated-documents"
  db_name                         = "${local.project_name}-document-metadata"
}

module "human_review_and_validation_lambda_function" {
  source = "../modules/lambda-function-builder"

  lambda_filename = "5-human-review-and-validation"

  environment_variables = {
    OUTPUT_BUCKET  = aws_s3_bucket.extracted_data_and_enriched_documents_bucket.bucket
    DYNAMODB_TABLE = aws_dynamodb_table.job_details.name
  }

  iam_role_name   = "AllowLambdaHumanReviewAndValidation"
  iam_policy_name = "AllowLambdaHumanReviewAndValidation"
  iam_policy_json = data.aws_iam_policy_document.human_review_policy.json
}

data "aws_iam_policy_document" "human_review_policy" {
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
    sid    = "AccessS3Buckets"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["${aws_s3_bucket.validated_documents.arn}/*"]
  }

  statement {
    sid    = "AccessDynamoDB"
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:Query"
    ]
    resources = [aws_dynamodb_table.job_details.arn]
  }

  statement {
    sid    = "StartA2IReview"
    effect = "Allow"

    actions = [
      "sagemaker:CreateFlowDefinition",
      "sagemaker:StartHumanLoop",
      "sagemaker:StopHumanLoop",
      "sagemaker:DescribeHumanLoop"
    ]
    resources = ["*"]
  }
}

resource "aws_sns_topic" "validation_notifications" {
  name = "${local.project_name}-validation-notifications"
}

resource "aws_sns_topic_policy" "validation_notifications" {
  arn = aws_sns_topic.validation_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaPublish"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.validation_notifications.arn
      }
    ]
  })
}

module "extracted_data_and_enriched_documents_bucket" {
  source = "../modules/document-storage"

  bucket_name   = local.validated_documents_bucket_name
  force_destroy = true
}

module "results_validation_lambda_function" {
  source = "../modules/lambda-function-builder"

  lambda_filename = "4-results-validation"

  environment_variables = {
    OUTPUT_BUCKET = aws_s3_bucket.validated_documents.bucket
  }

  iam_role_name   = "AllowLambdaValidateDocumentContent"
  iam_policy_name = "AllowLambdaValidateDocumentContent"
  iam_policy_json = data.aws_iam_policy_document.lambda_exec_policy.json
}

resource "aws_dynamodb_table" "job_details" {
  name           = local.db_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "DocumentId"
  stream_enabled = true

  attribute {
    name = "DocumentId"
    type = "S"
  }

  attribute {
    name = "DocumentType"
    type = "S"
  }

  attribute {
    name = "ProcessingStatus"
    type = "S"
  }

  global_secondary_index {
    name            = "DocumentTypeIndex"
    hash_key        = "DocumentType"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "ProcessingStatusIndex"
    hash_key        = "ProcessingStatus"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }
}