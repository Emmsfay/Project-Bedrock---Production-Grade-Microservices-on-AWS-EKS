terraform {
  backend "s3" {
    bucket         = "bedrock-tf-state-2354e"
    key            = "project-bedrock/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "bedrock-tf-locks"
    encrypt        = true
  }
}
