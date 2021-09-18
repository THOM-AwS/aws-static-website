data "aws_route53_zone" "selected" {
  name         = "${var.domain_name}."
  private_zone = false
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.selected.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.selected.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone
    evaluate_target_health = true
  }
}