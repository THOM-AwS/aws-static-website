
resource "aws_lambda_function" "cloudfront_lambda" {
  filename      = ".terraform/modules/aws-static-website/secheader.py.zip"
  function_name = "${replace(var.domain_name, ".", "-")}-sec-headers"
  role          =  aws_iam_role.iam_for_lambda.arn
  description   = "This lambda will add in security headers for origin responses."
  handler       = "secheader.lambda_handler"
  publish       = true

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256(".terraform/modules/aws-static-website/secheader.py.zip")

  runtime = "python3.8"
  tags    = var.tags

}

