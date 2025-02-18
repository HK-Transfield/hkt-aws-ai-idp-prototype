/*
Name:     Document Storage Module
Project:  AWS Generative AI Backed IDP Solution
Author:   HK Transfield, 2024

A module for configuring an S3 bucket with the appropriate ACL settings.
It also follows best security and compliance practices by enabling bucket 
ownership controls, enabling versioning, and defining lifecycle policies.
*/

################################################################################
# General configuration
################################################################################

# Append a randomly generated string to the bucket name to ensure uniqueness
resource "random_string" "this" {
  length  = 16
  special = false
  upper   = false
}

resource "aws_s3_bucket" "this" {
  bucket        = "${var.bucket_name}-${random_string.this.result}"
  force_destroy = var.force_destroy # DON'T DO THIS IN PRODUCTION

  tags = merge(
    var.tags,
    {
      "Name" = var.bucket_name
    },
  )
}

################################################################################
# Security and compliance configuration
################################################################################

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.object_ownership
  }
}

resource "aws_s3_bucket_acl" "this" {
  depends_on = [aws_s3_bucket_ownership_controls.this]

  bucket = aws_s3_bucket.this.id
  acl    = var.acl
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_status
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "abort-incomplete-multipart-upload"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}