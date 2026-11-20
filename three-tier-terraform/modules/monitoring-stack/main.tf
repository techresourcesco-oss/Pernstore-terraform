locals {
  prometheus_image = "${data.aws_ecr_repository.prometheus.repository_url}:latest"
  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = aws_cloudwatch_log_group.this.name
      "awslogs-region"        = var.aws_region
      "awslogs-stream-prefix" = "monitoring"
    }
  }
}

data "aws_ecr_repository" "prometheus" {
  name = "pern-prometheus"
}

resource "aws_ecr_repository" "prometheus" {
  name                 = "store/prometheus"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/monitoring-stack"
  retention_in_days = 30
  tags              = var.tags
}

resource "aws_ecs_task_definition" "this" {
  family                   = "monitoring-stack"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = var.execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "prometheus"
      image     = local.prometheus_image
      essential = true
      portMappings = [{
        containerPort = 9090
        hostPort      = 9090
        protocol      = "tcp"
      }]
      logConfiguration = local.log_configuration
    },
    {
      name      = "loki"
      image     = "grafana/loki:latest"
      essential = true
      command   = ["-config.file=/etc/loki/local-config.yaml"]
      portMappings = [{
        containerPort = 3100
        hostPort      = 3100
        protocol      = "tcp"
      }]
      logConfiguration = local.log_configuration
    },
    {
      name      = "grafana"
      image     = "grafana/grafana:latest"
      essential = true
      environment = [{
        name  = "GF_SERVER_HTTP_PORT"
        value = "3200"
        }, {
        name  = "GF_SMTP_ENABLED"
        value = "true"
        }, {
        name  = "GF_SMTP_HOST"
        value = var.grafana_smtp_host
        }, {
        name  = "GF_SMTP_USER"
        value = var.grafana_smtp_user
        }, {
        name  = "GF_SMTP_FROM_ADDRESS"
        value = var.grafana_smtp_from_address
        }, {
        name  = "GF_SMTP_FROM_NAME"
        value = var.grafana_smtp_from_name
      }]
      secrets = [{
        name      = "GF_SMTP_PASSWORD"
        valueFrom = var.grafana_smtp_password_secret_arn
      }]
      portMappings = [{
        containerPort = 3200
        hostPort      = 3200
        protocol      = "tcp"
      }]
      logConfiguration = local.log_configuration
    }
  ])

  tags = var.tags
}

resource "aws_ecs_service" "this" {
  name            = "monitoring-service"
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [var.security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.grafana_target_group_arn
    container_name   = "grafana"
    container_port   = 3200
  }

  load_balancer {
    target_group_arn = var.prometheus_target_group_arn
    container_name   = "prometheus"
    container_port   = 9090
  }

  load_balancer {
    target_group_arn = var.loki_target_group_arn
    container_name   = "loki"
    container_port   = 3100
  }

  tags = var.tags
}
