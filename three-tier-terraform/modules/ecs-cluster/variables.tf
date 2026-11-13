variable "name" {
  description = "Cluster name prefix"
  type        = string
}

variable "enable_container_insights" {
  description = "Enable ECS container insights"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
