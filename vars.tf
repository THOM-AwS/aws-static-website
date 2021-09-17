variable "domain_name" {
  description = "The domain name without its schema, ie www."
  type = string
  default = "hamer.cloud"
}

variable "create_logging_bucket" {
  description = "Do you want to create a nother bucket for logging"
  type = bool
  default = true
}

variable "versioning_status" {
  description = "Desired status for object versioning: True or False"
  type        = bool
  default     = false
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
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Desired setting to block public policies"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Desired setting to ignore public ACL's"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Desired setting to restrict public bucket policies for the bucket"
  type        = bool
  default     = true
}

variable "acm_certs" {
  description = "the certificate"
  type        = string
  default     = null
}

variable "price_class" {
  description = "price class"
  type        = string
  default     = null
}

locals {
  tags = merge(
    var.tags,
    {
      Name        = var.domain_name
      Environment = var.environment
    },
  )
}
