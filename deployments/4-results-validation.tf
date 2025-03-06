/*
Name:     IDP Results Validation
Project:  AWS Generative AI Backed IDP Solution
Author:   HK Transfield, 2025

This configuration is the final stage of the IDP pipeline. It uses business
rules to check for completeness and accuracy of the extracted data.
*/

locals {
  validated_documents_bucket_name = "${local.project_name}-validated-documents"
  db_name                         = "${local.project_name}-document-metadata"
}

################################################################################
# LAMBDA FUNCTION FOR RESULTS VALIDATION
################################################################################

################################################################################
# LAMBDA FUNCTION FOR RESULTS VALIDATION
################################################################################

data "aws_iam_policy_document" "allow_lambda_validate_document_content" {
  statement {
    sid    = "" #TODO: Add SID
    effect = "Allow"

    actions = [
      # TODO: Add actions
    ]
    resources = [""] #TODO: Add resources
  }
}

module "results_validation_lambda_function" {
  source = "../modules/lambda-function-builder"

  lambda_filename                  = "4-results-validation"
  cloudwatch_log_retention_in_days = 7

  environment_variables = {
    SOMETHING = "" #TODO: Add env variables?
  }

  iam_role_name   = "AllowLambdaValidateDocumentContent"
  iam_policy_name = "AllowLambdaValidateDocumentContent"
  iam_policy_json = data.aws_iam_policy_document.allow_lambda_validate_document_content

  tags = {
    project = local.project_tag
    name    = "4-results-validation"
  }
}

################################################################################
# LAMBDA FUNCTION FOR HUMAN REVIEW
################################################################################

module "human_review_and_validation_lambda_function" {
  source = "../modules/lambda-function-builder"

  lambda_filename                  = "5-human-review-and-validation"
  cloudwatch_log_retention_in_days = 7

  environment_variables = {
    OUTPUT_BUCKET  = module.extracted_data_and_enriched_documents_bucket.bucket_id
    DYNAMODB_TABLE = aws_dynamodb_table.job_details.name
  }

  iam_role_name   = "AllowLambdaHumanReviewAndValidation"
  iam_policy_name = "AllowLambdaHumanReviewAndValidation"
  iam_policy_json = data.aws_iam_policy_document.human_review_policy.json

  tags = {
    project = local.project_tag
    name    = "5-human-review-and-validation"
  }
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
    resources = [""] #TODO: Add resource to place validated content?
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

################################################################################
# SNS TOPIC FOR VALIDATION NOTIFICATIONS
################################################################################

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

################################################################################
# EXTRACTED AND VERIFIED DATA DYNAMODB TABLE
################################################################################\

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

