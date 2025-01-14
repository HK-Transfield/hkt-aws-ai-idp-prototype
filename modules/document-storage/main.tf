/*
Name: Document Storage Module
Author: HK Transfield, 2024

A simple module that creates an S3 bucket with the specified settings.
The intended use within this project is to store raw documents, classified
documents sorted by prefix, and the extracted data enriched douments.
*/

# To ensure that the bucket name is unique, we can append a random string to it
resource "random_string" "this" {
  length  = 16
  special = false
  upper   = false
}

resource "aws_s3_bucket" "this" {
  bucket        = "${var.bucket_name}-${random_string.this.result}"
  force_destroy = var.force_destroy
}

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