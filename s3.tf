resource "aws_s3_bucket" "root" {
  bucket        = lower(var.domain_name)
  tags          = var.tags
  force_destroy = false
}

resource "aws_s3_bucket" "www" {
  bucket        = lower("www.${var.domain_name}")
  force_destroy = false

  dynamic "logging" {
    for_each = length(keys(var.logging)) == 0 ? [] : [var.logging]

    content {
      target_bucket = logging.value.target_bucket
      target_prefix = lookup(logging.value, "target_prefix")
    }
  }
  tags = var.tags
}

resource "aws_s3_bucket_policy" "cloudfrontpolicy" {
  bucket = aws_s3_bucket.www.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "AllowCloudfrontOAC"
    Statement = [
      {
        Sid    = "AllowCloudfrontOAC"
        Effect = "Allow"
        "Principal" : {
          "Service" : "cloudfront.amazonaws.com"
        }
        Action = "s3:GetObject"
        Resource = [
          "${aws_s3_bucket.www.arn}/*",
        ]
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      },
      {
        "Sid" : "AllowDeployUser",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : aws_iam_user.website-user.arn
        },
        "Action" : [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:DeleteObject"
        ],
        "Resource" : [
          "arn:aws:s3:::www.${var.domain_name}/*",
          "arn:aws:s3:::www.${var.domain_name}"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.www.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "log_bucket" {
  count         = var.create_logging_bucket ? 1 : 0
  bucket        = lower("${var.domain_name}-logging")
  force_destroy = false
  tags          = var.tags
}

resource "aws_s3_bucket_ownership_controls" "application_logs" {
  count  = var.create_logging_bucket ? 1 : 0
  bucket = aws_s3_bucket.log_bucket[0].id

  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "root" {
  bucket = aws_s3_bucket.root.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "www" {
  bucket = aws_s3_bucket.www.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log" {
  count  = var.create_logging_bucket ? 1 : 0
  bucket = aws_s3_bucket.log_bucket[0].bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
