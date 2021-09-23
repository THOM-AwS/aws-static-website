# aws-static-website
AWS static webiste with S3, Cloudfront, ACM and Route53

## This is a Terraform module, and must be used with a local implementation as in the example below. Dont pull this code down, rather reference it as the example shows as the source of your own module. 

This must be deployed after you have bought a domain and its live in route53. 

The domain_name variable is the same as your base domain without www. or http / https. ie: hamer.cloud 

The module will create you a root level bucket, and a www. bucket so that anyone visiting your TLD will resolve to the same distribution.

The main.tf is a file that will reference the external source module. Again, you do not need to download the source (this repo) to your local machine. its referenced with this block. along side this main.tf, you will create a locals.tf. this allows us to reuse the module in the same file, and abstract away to different 'workspaces'.

When the code is ran, we specify the workspace, here in this example the workspace is 'hamer' in the locals.tf

I write all my terraform with the three musketeers patterns. https://3musketeers.io/ Docker, Make, and Compose. This keeps your terraform and its associated versioning locked the same every time from every machine. it pulls the same version, the same image, every time. no more version error messages. This will be very important if you ever intend to colaborate with someone else. 

Find my implementation of this at https://github.com/THOM-AwS/mytf


example deployment code main.tf file:

### main.tf
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
### locals.tf
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