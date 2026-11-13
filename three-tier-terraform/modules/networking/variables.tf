variable "name" {
  description = "Project and environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones used for subnets"
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
}

variable "private_app_subnets" {
  description = "Private application subnet CIDR blocks"
  type        = list(string)
}

variable "private_data_subnets" {
  description = "Private database subnet CIDR blocks"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether NAT gateways should be created"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
