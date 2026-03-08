################################
# Developer IAM User
################################
resource "aws_iam_user" "dev_user" {
  name = "bedrock-dev-view"
}

################################
# Attach ReadOnlyAccess Managed Policy
################################
resource "aws_iam_user_policy_attachment" "readonly" {
  user       = aws_iam_user.dev_user.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

################################
# Allow Developer to PutObject in Assets Bucket
################################
resource "aws_iam_policy" "bucket_put_policy" {
  name = "bedrock-assets-put"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "s3:PutObject"
      Resource = "arn:aws:s3:::${local.assets_bucket_name}/*"
    }]
  })
}

resource "aws_iam_user_policy_attachment" "bucket_attach" {
  user       = aws_iam_user.dev_user.name
  policy_arn = aws_iam_policy.bucket_put_policy.arn
}

################################
# Lambda Execution Role
################################
resource "aws_iam_role" "lambda_role" {
  name = "bedrock-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}