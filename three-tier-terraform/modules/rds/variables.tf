variable "name" {
  description = "Project name prefix"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "pernstore"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.3"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GiB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum autoscaled storage"
  type        = number
  default     = 100
}

variable "subnet_ids" {
  description = "Subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "Security group IDs for the DB"
  type        = list(string)
}

variable "multi_az" {
  description = "Enable Multi-AZ"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Retention period for automated backups"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
