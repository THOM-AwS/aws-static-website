variable "bucket_name" {
  description = "Desired name for s3 backend state bucket"
  type        = string
  default     = null
}

variable "versioning_status" {
  description = "Desired status for object versioning: True or False"
  type        = bool
  default     = false
}

variable "attach_bucket_policy" {
  description = "Set if bucket should have bucket policy attached to it"
  type        = bool
  default     = false
}

variable "bucket_name_prefix" {
  description = "Create the bucket using a specified prefix for the name"
  type        = string
  default     = null
}

variable "logging" {
  description = "Access bucket logging configuration"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "The defining evironement of the Account: DEV, TST, STG, PRD, ROOT"
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "block_public_acls" {
  description = "Desired setting to block public ACL's"
  type = bool
  default = true
}

variable "block_public_policy" {
  description = "Desired setting to block public policies"
  type = bool
  default = true
}

variable "ignore_public_acls" {
  description = "Desired setting to ignore public ACL's"
  type = bool
  default = true
}

variable "restrict_public_buckets" {
  description = "Desired setting to restrict public bucket policies for the bucket"
  type = bool
  default = true
}

locals {
  tags = merge(
    var.tags,
    {
      Name        = var.bucket_name
      Environment = var.environment
    },
  )
}
