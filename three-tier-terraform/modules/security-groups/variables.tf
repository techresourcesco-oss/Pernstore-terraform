variable "name" {
  description = "Project prefix name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR allowed to access monitoring endpoints"
  type        = string
  default     = null
}

variable "monitoring_service_enabled" {
  description = "Whether to create the monitoring service security group and backend ingress"
  type        = bool
  default     = false
}

variable "frontend_port" {
  description = "Frontend port"
  type        = number
  default     = 3000
}

variable "backend_port" {
  description = "Backend port"
  type        = number
  default     = 9000
}

variable "tags" {
  description = "Tags applied to all security groups"
  type        = map(string)
  default     = {}
}
