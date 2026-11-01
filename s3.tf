# Apex bucket: nothing is served from it (one distribution answers for both
# names). It is kept so the bucket name stays reserved for this domain.
resource "aws_s3_bucket" "root" {
  bucket        = lower(var.domain_name)
  force_destroy = false
  tags          = local.tags
}

resource "aws_s3_bucket" "www" {
  bucket        = lower("www.${var.domain_name}")
  force_destroy = false
  tags          = local.tags
}

# CloudFront (this distribution only) reads the site bucket. Deploy access is
# granted by the caller's IAM role policy using the bucket_arn output; no
# principal is named here, so the module never owns deploy credentials.
resource "aws_s3_bucket_policy" "cloudfrontpolicy" {
  bucket = aws_s3_bucket.www.id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "AllowCloudfrontOAC"
    Statement = [
      {
        Sid       = "AllowCloudfrontOAC"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.www.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [aws_s3_bucket.www.arn, "${aws_s3_bucket.www.arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
    ]
  })
}

resource "aws_s3_bucket_versioning" "www" {
  bucket = aws_s3_bucket.www.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "www" {
  bucket     = aws_s3_bucket.www.id
  depends_on = [aws_s3_bucket_versioning.www]

  rule {
    id     = "expire-old-versions"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.www.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "root" {
  bucket = aws_s3_bucket.root.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
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
      sse_algorithm     = var.kms_key_arn == null ? "AES256" : "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = var.kms_key_arn != null
  }
}

# ---- access logs ---------------------------------------------------------------
# CloudFront standard logging writes with ACLs, so this bucket needs
# ObjectWriter ownership. Public access stays blocked.

resource "aws_s3_bucket" "log_bucket" {
  count         = var.create_logging_bucket && var.logging_bucket == null ? 1 : 0
  bucket        = lower("${var.domain_name}-logging")
  force_destroy = false
  tags          = local.tags
}

resource "aws_s3_bucket_ownership_controls" "application_logs" {
  count  = length(aws_s3_bucket.log_bucket)
  bucket = aws_s3_bucket.log_bucket[0].id

  rule {
    object_ownership = "ObjectWriter"
  }
}

# Chained: parallel config calls on one bucket can fail with OperationAborted.
resource "aws_s3_bucket_public_access_block" "log" {
  count      = length(aws_s3_bucket.log_bucket)
  bucket     = aws_s3_bucket.log_bucket[0].id
  depends_on = [aws_s3_bucket_ownership_controls.application_logs]

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log" {
  count      = length(aws_s3_bucket.log_bucket)
  bucket     = aws_s3_bucket.log_bucket[0].bucket
  depends_on = [aws_s3_bucket_public_access_block.log]
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "log" {
  count      = var.logging_retention_days == null ? 0 : length(aws_s3_bucket.log_bucket)
  bucket     = aws_s3_bucket.log_bucket[0].id
  depends_on = [aws_s3_bucket_server_side_encryption_configuration.log]

  rule {
    id     = "expire-logs"
    status = "Enabled"
    filter {}

    expiration {
      days = var.logging_retention_days
    }
  }
}
