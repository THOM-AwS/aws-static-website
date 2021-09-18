output "bucket_id" {
  description = "The name of the bucket"
  value       = aws_s3_bucket.www.id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.www.arn
}

output "user_details" {
  description = "User Name"
  value       = aws_iam_user.website-user.name
}

output "user_acces_key" {
  description = "User Name"
  value       = aws_iam_access_key.website-user.id
}

output "user_secret_access_key" {
  description = "User Name"
  value       = aws_iam_access_key.website-user.secret
}