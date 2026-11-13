variable "name" {
  description = "Project name prefix"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the ALB"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for the ALB"
  type        = string
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

variable "certificate_arn" {
  description = "ARN of the ACM certificate used for HTTPS"
  type        = string
  default     = ""
}

variable "internal" {
  description = "Internal or internet-facing ALB"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Deletion protection status"
  type        = bool
  default     = false
}

variable "frontend_health_check_path" {
  description = "Frontend target group health check path"
  type        = string
  default     = "/"
}

variable "backend_health_check_path" {
  description = "Backend target group health check path"
  type        = string
  default     = "/api"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
