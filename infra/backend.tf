terraform {
  backend "s3" {
    bucket         = "frizka-terraform-state"
    key            = "environment/dev/terraform.tfstate"
    region         = "us-east-1"
    use_lockfile   = true
    encrypt        = true
  }
}
