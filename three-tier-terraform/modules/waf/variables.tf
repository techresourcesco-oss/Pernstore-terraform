variable "name" {
  description = "Name prefix for the WAF ACL"
  type        = string
}

variable "distribution_arn" {
  description = "CloudFront distribution ARN"
  type        = string
  default     = ""
}

variable "associate_distribution" {
  description = "Whether to associate the ACL with a CloudFront distribution"
  type        = bool
  default     = true
}

variable "rate_limit" {
  description = "Requests per 5 minutes before block"
  type        = number
  default     = 2000
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
