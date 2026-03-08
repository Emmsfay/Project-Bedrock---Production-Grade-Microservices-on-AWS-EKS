provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project = "barakat-2026-capstone"
    }
  }
}
