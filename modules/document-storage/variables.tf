/*
Name:     Document Storage Module
Project:  AWS Generative AI Backed IDP Solution
Author:   HK Transfield, 2024
*/

################################################################################
# Bucket configurations
################################################################################

variable "bucket_name" {
  description = "Name of the bucket"
  type        = string
}

variable "object_ownership" {
  description = "The object ownership setting for the bucket"
  type        = string
  default     = "BucketOwnerPreferred"
}

variable "acl" {
  description = "The access control list to apply to the bucket"
  type        = string
  default     = "private"
}

variable "force_destroy" {
  description = "Whether to allow force destroying the bucket"
  type        = bool
  default     = true # this is just for demo purposes and should be set to false in production
}

variable "versioning_status" {
  type        = string
  default     = "Enabled"
  description = "The versioning status for the bucket"
}

variable "noncurrent_version_expiration_days" {
  type        = number
  default     = 30
  description = "The number of days to keep noncurrent versions"

}

################################################################################
# Other configurations
################################################################################

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the resource"
}
