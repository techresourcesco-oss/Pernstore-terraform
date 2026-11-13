output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution.arn
}

output "frontend_task_role_arn" {
  value = aws_iam_role.frontend_task.arn
}

output "backend_task_role_arn" {
  value = aws_iam_role.backend_task.arn
}
