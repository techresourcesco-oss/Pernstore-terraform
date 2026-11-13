terraform {
  backend "s3" {
    bucket         = "pern-store-tf-state-391359249876-b7e91d4c8a2f6e30"
    dynamodb_table = "state-lock"
    key            = "Terraform/dev/terraform.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
  }
}