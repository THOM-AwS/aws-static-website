resource "aws_iam_user" "website-user" {
  name = "website-${var.domain_name}-user"
  path = "/website-users/"
  force_destroy = true
  tags = var.tags
}

resource "aws_iam_access_key" "website-user" {
  user = aws_iam_user.website-user.name
}

resource "aws_iam_user_policy" "website-user" {
  name = "website-${var.domain_name}-user"
  user = aws_iam_user.website-user.name
  tags = var.tags
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "website-${var.domain_name}-upload",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucketMultipartUploads",
                "s3:ListMultipartUploadParts",
                "s3:AbortMultipartUpload",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::www.${var.domain_name}/*",
                "arn:aws:s3:::www.${var.domain_name}"
            ]
        },
        {
            "Sid": "cloudfront-${var.domain_name}-invalidation",
            "Effect": "Allow",
            "Action": [
                "cloudfront:CreateInvalidation"
            ],
            "Resource": [
                "${aws_cloudfront_distribution.s3_distribution.arn}"
            ]
        }
    ]
}
EOF
}