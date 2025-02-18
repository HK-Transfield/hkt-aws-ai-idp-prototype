/*
Name: Event Handler Module
Project:  AWS Generative AI Backed IDP Solution
Author: HK Transifeld, 2024

This module creates an SNS topic and SQS queue for Textract notifications. 
Textract will send a completion notification to the SNS topic, which it will 
send to the SQS queue. The SQS queue will invoke a Lambda function to process 
and read the Textract results.
*/

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

################################################################################
# Topic and Queue configurations
################################################################################

resource "aws_sns_topic" "this" {
  name = var.sns_topic_name

  tags = merge(
    var.tags,
    {
      "Name" = var.sns_topic_name
    },
  )
}

resource "aws_sqs_queue" "this" {
  name = var.sqs_queue_name

  tags = merge(
    var.tags,
    {
      "Name" = var.sqs_queue_name
    },
  )
}

resource "aws_sns_topic_subscription" "this" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.this.arn

  # allow SNS to send message to SQS
  depends_on = [aws_sqs_queue_policy.this]
}

# Enable dead-letter queue for SQS
resource "aws_sqs_queue_redrive_policy" "this" {
  queue_url = aws_sqs_queue.this.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.this.arn
    maxReceiveCount     = 3
  })
}

################################################################################
# IAM role and policies configurations
################################################################################

data "aws_iam_policy_document" "sns" {
  statement {
    sid    = "AllowSQSSubscription"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sqs.amazonaws.com"]
    }

    actions   = ["sns:publish"]
    resources = [aws_sns_topic.this.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sqs_queue.this.arn]
    }
  }
}

resource "aws_sns_topic_policy" "this" {
  arn    = aws_sns_topic.this.arn
  policy = data.aws_iam_policy_document.sns.json
}

data "aws_iam_policy_document" "sqs" {
  statement {
    sid    = "SQSSendMessage"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.this.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.this.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "this" {
  queue_url = aws_sqs_queue.this.id
  policy    = data.aws_iam_policy_document.sqs.json
}

resource "aws_iam_role" "this" {
  name = "sns_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "textract.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "this" {
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.this.arn
        Condition = {
          StringEquals = {
            "AWS:SourceOwner" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

################################################################################
# Logging and monitoring configurations
################################################################################

resource "aws_cloudwatch_metric_alarm" "sqs_queue_depth" {
  alarm_name          = "${var.sqs_queue_name}-QueueDepth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 100 # Adjust threshold based on your needs
  alarm_actions       = [aws_sns_topic.this.arn]
  dimensions = {
    QueueName = aws_sqs_queue.this.name
  }
}

