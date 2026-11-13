output "service_name" {
  value = var.enabled ? aws_ecs_service.this[0].name : null
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.this.name
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.this.arn
}
