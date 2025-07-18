terraform {
  backend "s3" {
    bucket       = "personal-website-backend-tf-state"
    key          = "personal-website-backend/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
