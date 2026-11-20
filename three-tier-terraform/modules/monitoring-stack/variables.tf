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

variable "private_subnets" {
  description = "Private subnet IDs for the monitoring service"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for the monitoring service"
  type        = string
}

variable "grafana_target_group_arn" {
  description = "ALB target group ARN for the Grafana container"
  type        = string
}

variable "prometheus_target_group_arn" {
  description = "ALB target group ARN for the Prometheus container"
  type        = string
}

variable "loki_target_group_arn" {
  description = "ALB target group ARN for the Loki container"
  type        = string
}

variable "grafana_smtp_host" {
  description = "SMTP host and port for Grafana alert email"
  type        = string
}

variable "grafana_smtp_user" {
  description = "SMTP user for Grafana alert email"
  type        = string
}

variable "grafana_smtp_from_address" {
  description = "Sender address for Grafana alert email"
  type        = string
}

variable "grafana_smtp_from_name" {
  description = "Sender name for Grafana alert email"
  type        = string
}

variable "grafana_smtp_password_secret_arn" {
  description = "Secrets Manager ARN containing the Grafana SMTP app password"
  type        = string
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
