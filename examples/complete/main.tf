# A site that owns its certificate, headers and request function, and calls
# the module for the bucket, distribution and DNS.

terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

locals {
  domain = "example.com"
}

data "aws_route53_zone" "site" {
  name = "${local.domain}."
}

resource "aws_acm_certificate" "site" {
  domain_name               = local.domain
  subject_alternative_names = ["www.${local.domain}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.site.domain_validation_options : dvo.domain_name => dvo
  }

  zone_id         = data.aws_route53_zone.site.zone_id
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  ttl             = 300
  records         = [each.value.resource_record_value]
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "site" {
  certificate_arn         = aws_acm_certificate.site.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

# The site's own headers. Another site calling the module defines its own.
resource "aws_cloudfront_response_headers_policy" "site" {
  name = "example-com-security-headers"

  security_headers_config {
    content_security_policy {
      content_security_policy = "default-src 'self'; img-src 'self' data:; object-src 'none'; frame-ancestors 'none'; base-uri 'self'"
      override                = true
    }
    strict_transport_security {
      access_control_max_age_sec = 63072000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }

  custom_headers_config {
    items {
      header   = "Permissions-Policy"
      value    = "camera=(), microphone=(), geolocation=()"
      override = true
    }
  }
}

resource "aws_cloudfront_function" "viewer_request" {
  name    = "viewer-request-example-com"
  runtime = "cloudfront-js-2.0"
  comment = "www to apex redirect and clean URLs for ${local.domain}"
  publish = true
  code    = file("${path.module}/../viewer-request.js")
}

module "site" {
  source = "../.."

  domain_name                 = local.domain
  hosted_zone_id              = data.aws_route53_zone.site.zone_id
  certificate_arn             = aws_acm_certificate_validation.site.certificate_arn
  response_headers_policy_id  = aws_cloudfront_response_headers_policy.site.id
  viewer_request_function_arn = aws_cloudfront_function.viewer_request.arn
  error_page_path             = "/404.html"
  environment                 = "prod"
}

# Deploy access belongs to the caller: an OIDC role scoped to this one site.
data "aws_iam_policy_document" "deploy" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [module.site.bucket_arn]
  }

  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${module.site.bucket_arn}/*"]
  }

  statement {
    actions   = ["cloudfront:CreateInvalidation", "cloudfront:GetInvalidation"]
    resources = [module.site.cloudfront_distribution_arn]
  }
}

output "deploy_policy_json" {
  value = data.aws_iam_policy_document.deploy.json
}
