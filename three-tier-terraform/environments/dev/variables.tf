variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "pern-store"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "tier" {
  description = "Environment tier"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
}

variable "private_app_subnets" {
  type    = list(string)
  default = ["10.20.11.0/24", "10.20.12.0/24", "10.20.13.0/24"]
}

variable "private_data_subnets" {
  type    = list(string)
  default = ["10.20.21.0/24", "10.20.22.0/24", "10.20.23.0/24"]
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "certificate_arn" {
  type    = string
  default = ""
}

variable "frontend_container_port" {
  type    = number
  default = 3000
}

variable "backend_container_port" {
  type    = number
  default = 9000
}

variable "frontend_container_image" {
  type    = string
  default = "438424052578.dkr.ecr.ap-southeast-2.amazonaws.com/store/frontend:v2"
}

variable "backend_container_image" {
  type    = string
  default = "438424052578.dkr.ecr.ap-southeast-2.amazonaws.com/store/backend:latest"
}

variable "enable_frontend_service" {
  type    = bool
  default = false
}

variable "enable_backend_service" {
  type    = bool
  default = false
}

variable "frontend_desired_count" {
  type    = number
  default = 1
}

variable "backend_desired_count" {
  type    = number
  default = 1
}

variable "database_name" {
  type    = string
  default = "pernstore"
}

variable "database_username" {
  type    = string
  default = "postgres"
}

variable "db_engine_version" {
  type    = string
  default = "16.15"
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_max_allocated_storage" {
  type    = number
  default = 100
}

variable "rds_multi_az" {
  type    = bool
  default = false
}

variable "backup_retention_period" {
  type    = number
  default = 1
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "performance_insights_enabled" {
  type    = bool
  default = false
}
