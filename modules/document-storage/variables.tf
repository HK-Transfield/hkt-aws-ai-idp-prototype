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
  default     = false
}