terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# No provider block: the caller's aws provider must be in us-east-1, where
# CloudFront certificates and Lambda@Edge live. Keeping providers out of the
# module lets callers use count, for_each and depends_on on it.

locals {
  tags            = merge(var.tags, var.environment == null ? {} : { Environment = var.environment })
  origin_id       = "www.${var.domain_name}-origin"
  logging_bucket  = var.logging_bucket != null ? var.logging_bucket : (var.create_logging_bucket ? aws_s3_bucket.log_bucket[0].bucket_domain_name : null)
  cache_policy_id = var.cache_policy_id != null ? var.cache_policy_id : data.aws_cloudfront_cache_policy.optimized[0].id
  origin_request_policy_id = (var.origin_request_policy_id != null
  ? var.origin_request_policy_id : data.aws_cloudfront_origin_request_policy.cors_s3[0].id)
}

data "aws_cloudfront_cache_policy" "optimized" {
  count = var.cache_policy_id == null ? 1 : 0
  name  = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "cors_s3" {
  count = var.origin_request_policy_id == null ? 1 : 0
  name  = "Managed-CORS-S3Origin"
}
