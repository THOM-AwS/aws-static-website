variable "domain_name" {
  description = "The domain name without www prefix"
  type        = string
}

variable "create_logging_bucket" {
  description = "Create a separate bucket for CloudFront access logs"
  type        = bool
  default     = true
}

variable "acm_certificate_domain" {
  default     = null
  description = "Domain of the ACM certificate (defaults to hosted_zone)"
}

variable "hosted_zone" {
  default     = null
  description = "Route53 hosted zone"
}

variable "logging" {
  description = "Access bucket logging configuration"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment tag: dev, staging, prod"
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "price_class" {
  default     = "PriceClass_All"
  description = "CloudFront distribution price class"
}

variable "use_default_domain" {
  default     = false
  description = "Use CloudFront website address without Route53 and ACM certificate"
}

variable "use_sec_headers" {
  default     = true
  type        = bool
  description = "Create and attach Lambda@Edge security headers function"
}

variable "security_headers_source" {
  default     = null
  type        = string
  description = "Path to a custom secheader.py file. If null, uses the module default."
}

locals {
  tags = merge(
    var.tags,
    {
      Name        = var.domain_name
      Environment = var.environment
    },
  )
}
