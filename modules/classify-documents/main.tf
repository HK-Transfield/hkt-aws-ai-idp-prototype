data "aws_region" "current" {}

data "aws_sqs_queue" "current_queue" {
  name = var.sqs_queue_name
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