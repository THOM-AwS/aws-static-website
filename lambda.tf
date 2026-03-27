data "archive_file" "secheader_zip" {
  type        = "zip"
  source_file = var.security_headers_source != null ? var.security_headers_source : "${path.module}/secheader.py"
  output_path = "${path.module}/secheader.py.zip"
}

resource "aws_lambda_function" "cloudfront_lambda" {
  filename         = data.archive_file.secheader_zip.output_path
  function_name    = "${replace(var.domain_name, ".", "-")}-sec-headers"
  role             = aws_iam_role.iam_for_lambda.arn
  description      = "Lambda@Edge security headers for ${var.domain_name}"
  handler          = "secheader.lambda_handler"
  publish          = true
  source_code_hash = data.archive_file.secheader_zip.output_base64sha256
  runtime          = "python3.11"
  tags             = var.tags
}
