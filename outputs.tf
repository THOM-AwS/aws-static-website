output "bucket_id" {
  description = "The name of the www S3 bucket"
  value       = aws_s3_bucket.www.id
}

output "bucket_arn" {
  description = "The ARN of the www S3 bucket"
  value       = aws_s3_bucket.www.arn
}

output "user_details" {
  description = "IAM deploy user name"
  value       = aws_iam_user.website-user.name
}

output "user_acces_key" {
  description = "IAM deploy user access key ID"
  value       = aws_iam_access_key.website-user.id
}

output "user_secret_access_key" {
  description = "IAM deploy user secret access key"
  value       = aws_iam_access_key.website-user.secret
  sensitive   = true
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for cache invalidation"
  value       = aws_cloudfront_distribution.s3_distribution.id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.s3_distribution.arn
}
