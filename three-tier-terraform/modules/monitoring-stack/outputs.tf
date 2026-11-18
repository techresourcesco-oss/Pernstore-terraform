output "prometheus_repository_url" {
  value = data.aws_ecr_repository.prometheus.repository_url
}
