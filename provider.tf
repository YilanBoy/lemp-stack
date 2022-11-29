provider "aws" {
  region = "ap-northeast-1"

  # allowed_account_ids = [""]

  default_tags {
    tags = {
      Service     = "lemp stack"
      Environment = "production"
      Owner       = "John"
    }
  }
}
