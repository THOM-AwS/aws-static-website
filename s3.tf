resource "aws_s3_bucket" "root" {
  bucket = lower(var.domain_name)
  acl    = "private"
  tags   = var.tags
  force_destroy = true
}

resource "aws_s3_bucket" "www" {
  bucket = lower("www.${var.domain_name}")
  acl    = "private"
  force_destroy = true
  # server_side_encryption_configuration {
  #   rule {
  #     apply_server_side_encryption_by_default {
  #       kms_master_key_id = aws_kms_key.mykey.arn
  #       sse_algorithm     = "aws:kms"
  #     }
  #   }
  # }
  dynamic "logging" {
    for_each = length(keys(var.logging)) == 0 ? [] : [var.logging]

    content {
      target_bucket = logging.value.target_bucket
      target_prefix = lookup(logging.value, "target_prefix")
    }
  }
  versioning {
    enabled = var.versioning_status
  }
  tags = var.tags
}

resource "aws_s3_bucket_policy" "cloudfrontpolicy" {
  bucket = aws_s3_bucket.www.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "AllowCloudfrontOAI"
    Statement = [
      {
        Sid    = "AllowCloudfrontOAI"
        Effect = "Allow"
        "Principal" : {
          "AWS" : aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn
        }
        Action = "s3:GetObject"
        Resource = [
          aws_s3_bucket.www.arn,
          "${aws_s3_bucket.www.arn}/*",
        ]
      },
      {
            "Sid": "allow account access",
            "Effect": "Allow",
            "Principal": {
                "AWS": var.user_arn
            },
            "Action": [
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:GetObject",
                "s3:GetObjectAcl",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::www.${domain_name}/*",
                "arn:aws:s3:::www.${domain_name}"
            ]
        }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.www.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

resource "aws_s3_bucket" "log_bucket" {
  count  = var.create_logging_bucket ? 1 : 0
  bucket = lower("${var.domain_name}-logging")
  acl    = "log-delivery-write"
  force_destroy = true
  # server_side_encryption_configuration {
  #   rule {
  #     apply_server_side_encryption_by_default {
  #       kms_master_key_id = aws_kms_key.mykey.arn
  #       sse_algorithm     = "aws:kms"
  #     }
  #   }
  # }
  tags = var.tags
}
