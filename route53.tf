# A and AAAA for both names (the distribution has IPv6 enabled).
locals {
  alias_records = {
    for pair in setproduct(["root", "www"], ["A", "AAAA"]) :
    "${pair[0]}-${pair[1]}" => { name = pair[0] == "root" ? var.domain_name : "www.${var.domain_name}", type = pair[1] }
  }
}

resource "aws_route53_record" "alias" {
  for_each = local.alias_records

  zone_id = var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}

# v1 addresses, so callers upgrade without replacing the A records.
moved {
  from = aws_route53_record.root
  to   = aws_route53_record.alias["root-A"]
}

moved {
  from = aws_route53_record.www
  to   = aws_route53_record.alias["www-A"]
}
