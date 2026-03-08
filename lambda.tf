# -----------------------------
# S3 Bucket for Lambda assets
# -----------------------------
resource "aws_s3_bucket" "assets" {
  bucket = local.assets_bucket_name

}

# -----------------------------
# Lambda Function
# -----------------------------
resource "aws_lambda_function" "asset_processor" {
  function_name = "bedrock-asset-processor"
  runtime       = "python3.11"
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.lambda_role.arn
  filename      = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")
}

# -----------------------------
# Allow S3 to invoke Lambda
# -----------------------------
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.asset_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.assets.arn
}

# -----------------------------
# S3 Bucket Notification to trigger Lambda
# -----------------------------
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.assets.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.asset_processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}