variable "aws_region" {
  description = "AWS region for the Terraform state bucket"
  type        = string
  default     = "ap-southeast-2"
}

variable "state_bucket_prefix" {
  description = "Lowercase S3-compatible prefix for the randomly suffixed Terraform state bucket"
  type        = string
  default     = "pern-store-tf-state"

  validation {
    condition = (
      length(var.state_bucket_prefix) >= 3 &&
      length(var.state_bucket_prefix) <= 29 &&
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.state_bucket_prefix)) &&
      !startswith(var.state_bucket_prefix, "xn--") &&
      !startswith(var.state_bucket_prefix, "sthree-") &&
      !startswith(var.state_bucket_prefix, "amzn-s3-demo-")
    )
    error_message = "The bucket prefix must be 3-29 lowercase letters, numbers, or hyphens, start and end with a letter or number, and not use an S3-reserved prefix."
  }
}

variable "tags" {
  description = "Tags applied to the state bucket"
  type        = map(string)
  default = {
    Project     = "pern-store"
    Environment = "bootstrap"
    ManagedBy   = "terraform"
  }
}
