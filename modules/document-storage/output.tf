output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "Value of the bucket domain name"
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_id" {
  description = "The name of the bucket"
  value       = aws_s3_bucket.this.id
}