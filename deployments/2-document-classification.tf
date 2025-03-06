/*
Name:     IDP Document Classification
Project:  AWS Generative AI Backed IDP Solution
Author:   HK Transfield, 2025

This configuration is the second stage of the IDP pipeline. Once data has been
captured and extracted, it needs to be categorised into specific classes before
further classification can be performed.
*/

locals {
  classified_documents_bucket_name = "${local.project_name}-classified-documents"
  classified_documents_object_key  = "classified-results"
  bedrock_model_id                 = "anthropic.claude-3-sonnet-20240229-v1:0"
}

################################################################################
# LAMBDA FUNCTION FOR CLASSIFYING TEXTRACT OUTPUT
################################################################################

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

  lambda_filename                  = "2a-classify-textract-output-bedrock"
  cloudwatch_log_retention_in_days = 7

  environment_variables = {
    OUTPUT_BUCKET     = module.classified_documents_bucket.bucket_id
    OUTPUT_OBJECT_KEY = local.classified_documents_object_key
    BEDROCK_MODEL_ID  = local.bedrock_model_id
  }

  iam_role_name   = "AllowLambdaClassifyDocuments"
  iam_policy_name = "AllowLambdaClassifyDocuments"
  iam_policy_json = data.aws_iam_policy_document.allow_lambda_classify_documents.json

  tags = {
    project = local.project_tag
    name    = "2-classify-textract-output"
  }
}

################################################################################
# CLASSIFIED DOCUMENTS BUCKET
################################################################################

module "classified_documents_bucket" {
  source = "../modules/document-storage"

  bucket_name   = local.classified_documents_bucket_name
  force_destroy = true

  tags = {
    project = local.project_tag
    name    = local.classified_documents_bucket_name
  }
}
