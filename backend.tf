terraform {
  backend "s3" {
    bucket         = "personal-website-backend-tf-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "personal-website-backend-tf-lock"
    encrypt        = true
  }
}
