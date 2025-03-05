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

  lambda_filename                  = "3-entity-extraction-and-content-enrichment"
  cloudwatch_log_retention_in_days = 7

  environment_variables = {
    TARGET_BUCKET           = aws_s3_bucket.enriched_documents_bucket.bucket
    CLASSIFIED_DOCS_OBJ_KEY = local.classified_documents_object_key
  }

  iam_role_name   = "AllowLambdaEnrichDocumentContent"
  iam_policy_name = "AllowLambdaEnrichDocumentContent"
  iam_policy_json = data.aws_iam_policy_document.allow_lambda_enrich_content.json

  tags = {
    project = local.project_tag
    name    = "3-entity-extraction-and-content-enrichment"
  }
}