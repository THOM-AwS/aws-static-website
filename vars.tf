variable "domain_name" {
  description = "The apex domain, without www. The site answers on both the apex and www."
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for domain_name. The caller owns the zone."
  type        = string
}

variable "certificate_arn" {
  description = "ARN of an ISSUED ACM certificate in us-east-1 covering domain_name and www.domain_name. The caller owns the certificate."
  type        = string

  validation {
    condition     = can(regex("^arn:aws:acm:us-east-1:[0-9]{12}:certificate/", var.certificate_arn))
    error_message = "certificate_arn must be an ACM certificate in us-east-1 (CloudFront only uses that region)."
  }
}

# Per-site behaviour is passed in, not built here, so every site owns its own
# headers, CSP and request rewriting instead of sharing the module's.

variable "response_headers_policy_id" {
  description = "ID of the site's aws_cloudfront_response_headers_policy (security headers, CSP). Required so no site ships without headers."
  type        = string
}

variable "viewer_request_function_arn" {
  description = "ARN of a published CloudFront Function to run at viewer-request (redirects, clean URLs). examples/viewer-request.js is a starting point."
  type        = string
  default     = null
}

variable "cache_policy_id" {
  description = "CloudFront cache policy ID. Defaults to the AWS managed CachingOptimized policy."
  type        = string
  default     = null
}

variable "origin_request_policy_id" {
  description = "CloudFront origin request policy ID. Defaults to the AWS managed CORS-S3Origin policy."
  type        = string
  default     = null
}

variable "error_page_path" {
  description = "Object served with HTTP 404 when the origin returns 403 for a missing key."
  type        = string
  default     = "/index.html"
}

variable "price_class" {
  description = "CloudFront distribution price class."
  type        = string
  default     = "PriceClass_All"
}

variable "create_logging_bucket" {
  description = "Create <domain>-logging for CloudFront access logs. Ignored when logging_bucket is set."
  type        = bool
  default     = true
}

variable "logging_bucket" {
  description = "Domain name of an existing bucket for CloudFront access logs (for example shared-logs.s3.amazonaws.com), so several sites can share one. The bucket must allow ACL writes from CloudFront."
  type        = string
  default     = null
}

variable "logging_prefix" {
  description = "Key prefix for CloudFront access logs."
  type        = string
  default     = "cloudfront-logs"
}

variable "logging_retention_days" {
  description = "Days to keep CloudFront access logs in the module's log bucket. Null keeps them forever (the v1 behaviour)."
  type        = number
  default     = null
}

variable "kms_key_arn" {
  description = "Customer managed KMS key for the site bucket. Its key policy must let cloudfront.amazonaws.com decrypt for this distribution. Null keeps SSE-S3 (AES256)."
  type        = string
  default     = null
}

variable "noncurrent_version_days" {
  description = "Days to keep old object versions in the site bucket, so a bad sync --delete can be rolled back."
  type        = number
  default     = 30
}

variable "environment" {
  description = "Environment tag: dev, staging, prod."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags for every resource."
  type        = map(string)
  default     = {}
}
