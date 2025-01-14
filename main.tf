/*
Name: AWS Generative AI Backed IDP Solution
Author: HK Transfield, 2024

This configuration deploys an Intelligent Document Processing (IDP) solution 
within in an AWS environment. The object of an IDP solution is to reduce the 
overall costs associated with typical document workflows.

At a high level, the solution performs the following functions:

  - Upload documents to an S3 bucket, triggering an asynchronous 
    Textract detection job 
  
  - Classify and enrich extracted text using AI/ML
  
  - Store results in another S3 bucket
  
  - Automate validation and review steps
  
  - Faciliate human reviews through A2I when necessary
  
  - Store verified data in a fully managed NoSQL database service 
    made available for downstream apps
*/

provider "aws" {
  region = "us-east-1"
}

resource "random_string" "this" {
  length  = 16
  special = false
  upper   = false
}

locals {
  project_org  = "hkt"
  project_tag  = "idp"
  project_name = "${local.project_org}-${local.project_tag}"
}

################################################################################
# DOCUMENT INGESTION AND TEXT EXTRACTION
################################################################################

locals {
  iam_entity_name = "AllowLambdaTextractAsyncJob"
  updates_name    = "${local.project_name}-textract-job"
}

module "input_documents" {
  source = "./modules/document-storage"

  bucket_name   = "hkt-idp-input-documents"
  force_destroy = true

}

# allow lambda to start textract jobs and access input documents bucket
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
    resources = ["${module.input_documents.bucket_arn}/*"]
  }
}

module "textract_events" {
  source = "./modules/textract-event-handler"

  sns_topic_name = "${local.updates_name}-topic"
  sqs_queue_name = "${local.updates_name}-queue"
}

# Lamda function to start Textract async detection job
module "textract_updates_lambda_function" {
  source = "./modules/lambda-function-builder"

  lambda_filename = "1-start-textract-async-detection-job"

  environment_variables = {
    SNS_TOPIC_ARN = module.textract_events.sns_topic_arn
    SNS_ROLE_ARN  = module.textract_events.sns_iam_role_arn
  }

  iam_role_name   = local.iam_entity_name
  iam_policy_name = local.iam_entity_name
  iam_policy_json = data.aws_iam_policy_document.allow_lambda_textract_async_job.json
}

################################################################################
# DOCUMENT CLASSIFICATION
################################################################################

resource "aws_lambda_event_source_mapping" "textract_output" {
  event_source_arn = module.textract_events.sqs_queue_arn
  function_name    = module.process_documents_lambda.function_arn
  batch_size       = 10
}

data "aws_iam_policy_document" "lambda_exec_policy" {
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
      "textract:DetectDocumentText",
      "s3:PutObject",
      "s3:GetObject"
    ]
    resources = ["*"]
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

module "classify_textract_output_lambda_function" {
  source = "./modules/lambda-function-builder"

  lambda_filename = "2-classify-textract-output"

  environment_variables = {
    OUTPUT_BUCKET = aws_s3_bucket.classified_documents.bucket
  }

  iam_role_name   = "AllowLambdaEnrichDocumentContent"
  iam_policy_name = "AllowLambdaEnrichDocumentContent"
  iam_policy_json = data.aws_iam_policy_document.lambda_exec_policy.json
}

module "classified_documents" {
  source = "./modules/document-storage"

  bucket_name   = "${local.project_name}-classfied-documents"
  force_destroy = true

}

################################################################################
# ENTITY EXTRACTION AND CONTENT ENRICHMENT
################################################################################

module "entity_extraction_and_content_enrichment" {
  source = "./modules/lambda-function-builder"

  lambda_filename = "3-entity-extraction-and-content-enrichment"

  environment_variables = {
    OUTPUT_BUCKET = aws_s3_bucket.enriched_documents.bucket
  }

  iam_role_name   = "AllowLambdaEnrichDocumentContent"
  iam_policy_name = "AllowLambdaEnrichDocumentContent"
  iam_policy_json = data.aws_iam_policy_document.lambda_exec_policy.json
}

################################################################################
# RESULTS VALIDATION
################################################################################

module "extracted_data_and_enriched_documents" {
  source = "./modules/document-storage"

  bucket_name   = "${local.project_name}-extracted-data-and-enriched-documents"
  force_destroy = true
}