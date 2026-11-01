# aws-static-website

Terraform module for a static website on S3 + CloudFront, answering on the
apex and `www.` of one domain.

The module creates what belongs to one site's hosting: the site bucket, the
distribution, its origin access control, and the DNS alias records. Anything a
site should decide for itself, or might share with other sites, is passed in:

| Input | Owned by the caller because |
|---|---|
| `certificate_arn` | certificates often cover several names or stacks |
| `hosted_zone_id` | the zone holds records the module does not manage |
| `response_headers_policy_id` | every site has its own CSP and headers |
| `viewer_request_function_arn` | redirects and URL rewriting are site behaviour |
| `cache_policy_id`, `origin_request_policy_id` | default to the AWS managed policies |
| `logging_bucket` | optional; several sites can share one log bucket |
| `kms_key_arn` | optional customer managed key for the site bucket |

A shared `logging_bucket` needs ObjectWriter ownership (`block_public_acls`
is fine: CloudFront's `awslogsdelivery` grant is not public), and whoever
applies needs `s3:GetBucketAcl` and `s3:PutBucketAcl` on it so CloudFront can
add its grant.

With `kms_key_arn`, the key policy must let `cloudfront.amazonaws.com` call
`kms:Decrypt` with `aws:SourceArn` = `cloudfront_distribution_arn`, and the
deploy role needs `kms:GenerateDataKey` and `kms:Decrypt` on the key
(condition `kms:ViaService` = `s3.us-east-1.amazonaws.com`). Objects already in
the bucket keep their old encryption until they are rewritten.

The module creates no IAM users, keys or roles. Deploy access is the caller's:
grant an OIDC role `s3:ListBucket` on `bucket_arn`, `s3:Get/Put/DeleteObject`
on `bucket_arn/*` and `cloudfront:CreateInvalidation` on
`cloudfront_distribution_arn`. See [examples/complete](examples/complete/main.tf).

## Usage

```hcl
provider "aws" {
  region = "us-east-1" # CloudFront certificates live here
}

resource "aws_cloudfront_response_headers_policy" "site" {
  name = "example-com-security-headers"
  # security_headers_config { ... }
}

module "site" {
  source = "github.com/THOM-AwS/aws-static-website?ref=v2.0.0"

  domain_name                = "example.com"
  hosted_zone_id             = data.aws_route53_zone.site.zone_id
  certificate_arn            = aws_acm_certificate_validation.site.certificate_arn
  response_headers_policy_id = aws_cloudfront_response_headers_policy.site.id
}
```

[examples/viewer-request.js](examples/viewer-request.js) is a CloudFront
Function that 301s `www.` to the apex and maps clean URLs to `.html` objects.
Copy it into your stack and pass its ARN in `viewer_request_function_arn`.

## What it creates

- `www.<domain>` bucket: private, OAC read for this distribution only, TLS
  required, versioned (old versions expire after `noncurrent_version_days`),
  SSE-S3 or SSE-KMS.
- `<domain>` bucket: empty and private. Kept so the name stays reserved.
- `<domain>-logging` bucket (unless `logging_bucket` is set or
  `create_logging_bucket = false`): private, ObjectWriter ownership for
  CloudFront's log ACLs. Logs are kept forever unless `logging_retention_days`
  is set.
- CloudFront distribution: HTTP/2 and HTTP/3, IPv6, TLSv1.2_2021 minimum,
  compression, 403 from S3 served as a 404 with `error_page_path`.
- Route53 A and AAAA aliases for the apex and `www.`.

## Upgrading from v1

v2 removes the deploy IAM user and its access key, the Lambda@Edge security
headers function and its role, the legacy origin access identity, and the
module's own `provider` block.

1. **Move deploys off the IAM user first.** Its access key is deleted on
   apply. Switch the site's pipeline to an OIDC role (see above) and confirm a
   deploy works before upgrading. Remove references to the outputs
   `user_details`, `user_acces_key` and `user_secret_access_key`, which are
   gone; plan fails while anything still reads them.
2. **Recreate your headers as a response headers policy** in your stack and
   pass its ID. The v1 `secheader.py` maps to `security_headers_config`
   (CSP, HSTS, frame options, content type options, referrer policy) plus
   `custom_headers_config` for anything else. Check the live headers after
   apply with `curl -sI https://<domain>/`.
3. **Pass `hosted_zone_id` and `certificate_arn`** instead of `hosted_zone` and
   `acm_certificate_domain`. `use_default_domain`, `use_sec_headers`,
   `security_headers_source`, `viewer_request_function` and `logging` are gone.
4. **Detach the Lambda@Edge before deleting it.** Terraform deletes the
   function before it updates the distribution, and CloudFront refuses to
   delete a function that is still attached ("replicated function"), so a
   plain upgrade fails and re-applying never gets past it. In the same change
   as the upgrade, move the function and its role into your root module and
   hold them there:

   ```hcl
   moved {
     from = module.site.aws_lambda_function.cloudfront_lambda
     to   = aws_lambda_function.legacy_sec_headers
   }
   moved {
     from = module.site.aws_iam_role.iam_for_lambda
     to   = aws_iam_role.legacy_sec_headers
   }
   # plus both resources, matching v1, with lifecycle { ignore_changes = all }
   ```

   The distribution then switches to the headers policy. A few hours later,
   once CloudFront has cleared the replicas, remove both resources in a second
   apply.
5. Plan changes to expect: in-place updates to the distribution (headers
   policy, HTTP/3, compression) and the bucket policy; new versioning,
   lifecycle, public access block and AAAA records (apply fails if you
   already have hand-made AAAA records for the apex or www); destroys of the IAM user,
   key and policy, and the OAI (the Lambda@Edge function and role go in the second apply). The A
   records move to `aws_route53_record.alias[...]` without replacement.
