variable "enabled" {
  description = "Whether this ECS service should be created"
  type        = bool
  default     = true
}

variable "service_name" {
  description = "Service name and task family"
  type        = string
}

variable "cluster_arn" {
  description = "ECS cluster ARN"
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "execution_role_arn" {
  description = "ECS task execution role ARN"
  type        = string
}

variable "task_role_arn" {
  description = "ECS task role ARN"
  type        = string
}

variable "container_image" {
  description = "Container image to run"
  type        = string
}

variable "container_port" {
  description = "Container port"
  type        = number
}

variable "subnets" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "security_groups" {
  description = "Security groups for tasks"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Assign public IP to tasks"
  type        = bool
  default     = false
}

variable "desired_count" {
  description = "Desired task count"
  type        = number
  default     = 1
}

variable "task_cpu" {
  description = "Task CPU units"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Task memory in MiB"
  type        = number
  default     = 512
}

variable "target_group_arn" {
  description = "Optional ALB target group ARN"
  type        = string
  default     = null
}

variable "container_environment" {
  description = "Environment variables for the task"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secrets to inject into the task"
  type        = map(string)
  default     = {}
}

variable "health_check_command" {
  description = "Container health check override"
  type        = list(string)
  default     = null
}

variable "health_check_grace_period" {
  description = "Grace period for ECS service health checks"
  type        = number
  default     = 60
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "autoscaling_enabled" {
  description = "Whether autoscaling is enabled"
  type        = bool
  default     = false
}

variable "min_capacity" {
  description = "Minimum task count"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum task count"
  type        = number
  default     = 3
}

variable "cpu_target_value" {
  description = "CPU target value for autoscaling"
  type        = number
  default     = 70
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
