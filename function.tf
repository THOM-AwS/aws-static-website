resource "aws_cloudfront_function" "viewer_request" {
  count   = var.viewer_request_function ? 1 : 0
  name    = "viewer-request-${replace(var.domain_name, ".", "-")}"
  runtime = "cloudfront-js-2.0"
  comment = "www to apex redirect and clean URL rewrite for ${var.domain_name}"
  publish = true
  code    = file("${path.module}/viewer-request.js")
}
