output "sns_topic_arn" {
  value = aws_sns_topic.this.arn
}

output "sqs_queue_arn" {
  value = aws_sqs_queue.this.arn

}

output "sqs_queue_url" {
  value = aws_sqs_queue.this.url

}

output "sns_iam_role_arn" {
  value = aws_iam_role.this.arn
}