resource "aws_iam_user" "website-user" {
  name          = "website-${replace(var.domain_name, ".", "-")}-user"
  path          = "/website-users/"
  force_destroy = true
  tags          = var.tags
}

resource "aws_iam_access_key" "website-user" {
  user = aws_iam_user.website-user.name
}

data "aws_caller_identity" "current" {}

resource "aws_iam_user_policy" "website-user" {
  name   = "website-${replace(var.domain_name, ".", "-")}-user"
  user   = aws_iam_user.website-user.name
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "WebsiteUpload",
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
            "Sid": "CloudfrontInvalidation",
            "Effect": "Allow",
            "Action": [
                "cloudfront:CreateInvalidation"
            ],
            "Resource": [
                "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.s3_distribution.id}"
            ]
        }
    ]
}
EOF
}


resource "aws_iam_role" "iam_for_lambda" {
  name                  = "website-${string(replace(var.domain_name, ".", "-"))}-execution_role"
  force_detach_policies = true

  inline_policy {
    name = "${replace(var.domain_name, ".", "-")}-policy"

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "PolicyPermissions",
          "Effect" : "Allow",
          "Action" : [
            "lambda:InvokeFunction",
            "lambda:EnableReplication*",
            "lambda:GetFunction",
            "iam:CreateServiceLinkedRole",
            "cloudfront:UpdateDistribution",
            "cloudfront:CreateDistribution"
          ],
          "Resource" : "arn:aws:lambda:us-east-1:${data.aws_caller_identity.current.account_id}:function:${replace(var.domain_name, ".", "-")}-sec-headers"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : [
            "arn:aws:logs:*:*:*"
          ]
        }
      ]
    })
  }

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Sid" : "TrustPolicy"
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : [
            "edgelambda.amazonaws.com",
            "lambda.amazonaws.com"
          ]
        },
      }
    ]
  })
}