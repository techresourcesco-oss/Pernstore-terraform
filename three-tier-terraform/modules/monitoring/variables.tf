variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "frontend_service_name" {
  description = "Frontend ECS service name"
  type        = string
}

variable "backend_service_name" {
  description = "Backend ECS service name"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch alarm"
  type        = string
}

variable "rds_instance_id" {
  description = "RDS instance identifier"
  type        = string
}

variable "ecs_cpu_alarm_threshold" {
  description = "CPU alarm threshold"
  type        = number
  default     = 80
}

variable "rds_cpu_alarm_threshold" {
  description = "RDS CPU alarm threshold"
  type        = number
  default     = 80
}

variable "log_retention_days" {
  description = "CloudWatch retention period"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
