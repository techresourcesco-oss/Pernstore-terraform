variable "cluster_arn" {
  description = "ECS cluster ARN"
  type        = string
}

variable "execution_role_arn" {
  description = "ECS task execution role ARN"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC hosting the monitoring service"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR allowed to access the monitoring endpoints"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet IDs for the monitoring service"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
