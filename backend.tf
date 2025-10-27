terraform {
  backend "s3" {
    bucket         = "terraform-state-test-20251023"
    key            = "terraform-k8s-rancher/production.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-locks-test"
    encrypt        = true
  }
}