# in multi-person collaboration, terraform's best practice recommends using state lock and remote state
# there is no problem to delete this block, only means that we are using local state here
terraform {
  # ref: <https://www.terraform.io/language/settings/backends/s3>
  backend "s3" {
    bucket         = "terraform-state-files"
    key            = "lemp-terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-state-locking"
  }
}
