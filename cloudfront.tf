resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "s3-oac-${var.domain_name}"
  description                       = "OAC for ${var.domain_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  depends_on = [
    aws_s3_bucket.www,
    aws_s3_bucket.log_bucket
  ]

  origin {
    domain_name              = aws_s3_bucket.www.bucket_regional_domain_name
    origin_id                = "www.${var.domain_name}-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.domain_name} Origin."
  default_root_object = "index.html"

  logging_config {
    include_cookies = true
    bucket          = "${lower("${var.domain_name}-logging")}.s3.amazonaws.com"
    prefix          = "cloudfront-logs"
  }

  aliases = [
    "www.${var.domain_name}",
    var.domain_name
  ]

  default_cache_behavior {

    dynamic "lambda_function_association" {
      for_each = var.use_sec_headers ? [1] : []
      content {
        event_type   = "origin-response"
        include_body = false
        lambda_arn   = aws_lambda_function.cloudfront_lambda.qualified_arn
      }
    }

    allowed_methods = [
      "GET",
      "HEAD",
    ]

    cached_methods = [
      "GET",
      "HEAD",
    ]
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.this.id
    cache_policy_id          = data.aws_cloudfront_cache_policy.this.id
    target_origin_id         = "www.${var.domain_name}-origin"

    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = var.price_class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  dynamic "viewer_certificate" {
    for_each = local.default_certs
    content {
      cloudfront_default_certificate = true
    }
  }

  dynamic "viewer_certificate" {
    for_each = local.acm_certs
    content {
      acm_certificate_arn      = data.aws_acm_certificate.acm_cert[0].arn
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1.2_2021"
    }
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    error_caching_min_ttl = 0
    response_page_path    = "/index.html"
  }

  wait_for_deployment = true
  tags                = var.tags
}

data "aws_cloudfront_origin_request_policy" "this" {
  name = "Managed-CORS-S3Origin"
}

data "aws_cloudfront_cache_policy" "this" {
  name = "Managed-CachingOptimized"
}
