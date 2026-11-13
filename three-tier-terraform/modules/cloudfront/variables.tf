variable "origin_domain_name" {
  description = "ALB DNS name used as origin"
  type        = string
}

variable "aliases" {
  description = "Optional DNS aliases"
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for CloudFront HTTPS"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
