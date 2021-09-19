# aws-static-website
AWS static webiste with S3, Cloudfront, ACM and Route53

This must be deployed once you have bought a domain and its live in route53. the domain_name variable is the same as your base domain without www. or http / https. ie: hamer.cloud 

The module will create you a root level bucket, and a www. bucket so that anyone visiting your TLD will resolve to the same distribution.

example deployment code:

main.tf
```
module "aws-static-website" {
  source      = "github.com/THOM-AwS/aws-static-website"
  domain_name = local.workspace["domain_name"]
  hosted_zone = local.workspace["domain_name"]
  environment = "prod"
  tags = {
    "Stack" = local.workspace["domain_name"]
  }

}
```

locals.tf
```
locals {

  env = {
    hamer = {
      aws_profile = "hamer"
      aws_region  = "us-east-1"
      domain_name = "hamer.cloud"
    }
  }

  workspace = local.env[terraform.workspace]
}
```