################################################################################
# UPLOADED DOCUMENT STORAGE
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

  tags = {
    project = local.project_tag
    name    = local.captured_documents_bucket_name
  }
}

################################################################################
# LAMBDA FUNCTION FOR STARTING TEXTRACT ASYNC DETECTION JOB
################################################################################

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

  lambda_filename                  = "1-start-textract-async-detection-job"
  cloudwatch_log_retention_in_days = 7

  environment_variables = {
    SNS_TOPIC_ARN = module.textract_events.sns_topic_arn
    SNS_ROLE_ARN  = module.textract_events.sns_iam_role_arn
  }

  iam_role_name   = "AllowLambdaTextractAsyncJob"
  iam_policy_name = "AllowLambdaTextractAsyncJob"
  iam_policy_json = data.aws_iam_policy_document.allow_lambda_textract_async_job.json

  tags = {
    project = local.project_tag
    name    = "1-start-textract-async-detection-job"
  }
}

################################################################################
# TEXTRACT SNS TOPIC AND SQS QUEUE HANDLER
################################################################################

module "textract_events" {
  source = "../modules/textract-event-handler"

  sns_topic_name = "${local.updates_name}-topic"
  sqs_queue_name = "${local.updates_name}-queue"

  tags = {
    project = local.project_tag
    name    = local.updates_name
  }
}