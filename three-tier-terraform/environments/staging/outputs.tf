output "vpc_id" {
  value = module.networking.vpc_id
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "frontend_repository_url" {
  value = local.frontend_repository_url
}

output "backend_repository_url" {
  value = local.backend_repository_url
}

output "rds_endpoint" {
  value = module.rds.db_instance_address
}
