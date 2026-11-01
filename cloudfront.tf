resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "s3-oac-${var.domain_name}"
  description                       = "OAC for ${var.domain_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.www.bucket_regional_domain_name
    origin_id                = local.origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2and3"
  comment             = "${var.domain_name} Origin."
  default_root_object = "index.html"

  dynamic "logging_config" {
    for_each = local.logging_bucket == null ? [] : [local.logging_bucket]
    content {
      include_cookies = true
      bucket          = logging_config.value
      prefix          = var.logging_prefix
    }
  }

  aliases = [
    "www.${var.domain_name}",
    var.domain_name,
  ]

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    dynamic "function_association" {
      for_each = var.viewer_request_function_arn == null ? [] : [var.viewer_request_function_arn]
      content {
        event_type   = "viewer-request"
        function_arn = function_association.value
      }
    }

    cache_policy_id            = local.cache_policy_id
    origin_request_policy_id   = local.origin_request_policy_id
    response_headers_policy_id = var.response_headers_policy_id
    target_origin_id           = local.origin_id
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
  }

  price_class = var.price_class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  custom_error_response {
    error_code            = 403
    response_code         = 404
    error_caching_min_ttl = 0
    response_page_path    = var.error_page_path
  }

  wait_for_deployment = true
  tags                = local.tags
}
