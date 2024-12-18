output "sns_topic_arn" {
  value = aws_sns_topic.this.arn
}

output "sns_iam_role_arn" {
  value = aws_iam_role.this.arn
}