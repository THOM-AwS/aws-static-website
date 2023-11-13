resource "aws_s3_bucket" "root" {
  bucket        = lower(var.domain_name)
  tags          = var.tags
  force_destroy = true
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket" "www" {
  bucket        = lower("www.${var.domain_name}")
  force_destroy = true
  lifecycle {
    prevent_destroy = false
  }

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
        "Sid" : "allow account access",
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

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

resource "aws_s3_bucket" "log_bucket" {
  count         = var.create_logging_bucket ? 1 : 0
  bucket        = lower("${var.domain_name}-logging")
  acl           = "log-delivery-write"
  force_destroy = true
  lifecycle {
    prevent_destroy = false
  }
  tags = var.tags
}

# resource "aws_s3_bucket_acl" "log" {
#   bucket = aws_s3_bucket.log_bucket[0].id
#   acl    = "log-delivery-write"
# }

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
  bucket = aws_s3_bucket.log_bucket[0].bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
