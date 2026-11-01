output "bucket_id" {
  description = "Name of the www (site) bucket."
  value       = aws_s3_bucket.www.id
}

output "bucket_arn" {
  description = "ARN of the www (site) bucket. Grant deploy roles s3:ListBucket on it and Put/Get/DeleteObject on <arn>/*."
  value       = aws_s3_bucket.www.arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID, for cache invalidation."
  value       = aws_cloudfront_distribution.s3_distribution.id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN. Grant deploy roles cloudfront:CreateInvalidation on it, and use it in a KMS key policy when kms_key_arn is set."
  value       = aws_cloudfront_distribution.s3_distribution.arn
}

output "cloudfront_domain_name" {
  description = "The distribution's *.cloudfront.net name."
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "origin_access_control_id" {
  description = "ID of the OAC the distribution uses to read the bucket."
  value       = aws_cloudfront_origin_access_control.default.id
}
