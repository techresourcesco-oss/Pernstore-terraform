output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "frontend_security_group_id" {
  value = aws_security_group.frontend.id
}

output "backend_security_group_id" {
  value = aws_security_group.backend.id
}

output "monitoring_security_group_id" {
  value = var.monitoring_service_enabled ? aws_security_group.monitoring[0].id : null
}

output "rds_security_group_id" {
  value = aws_security_group.rds.id
}
