locals {
  cloudwatch_log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = aws_cloudwatch_log_group.this.name
      "awslogs-region"        = var.aws_region
      "awslogs-stream-prefix" = var.service_name
    }
  }

  log_router_log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-group"         = aws_cloudwatch_log_group.this.name
      "awslogs-region"        = var.aws_region
      "awslogs-stream-prefix" = "${var.service_name}-log-router"
    }
  }

  loki_log_configuration = {
    logDriver = "awsfirelens"
    options = {
      Name        = "loki"
      Host        = var.firelens_loki_host
      Port        = "3100"
      labels      = "job=pern-backend"
      remove_keys = "container_id,ecs_task_arn"
      line_format = "json"
    }
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.service_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.service_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode(concat(
    [
      merge({
        name      = var.service_name
        image     = var.container_image
        essential = true
        cpu       = 0
        portMappings = [{
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }]
        environment = concat(
          [for key, value in var.container_environment : {
            name  = key
            value = tostring(value)
          }],
          var.new_relic_license_key == null ? [] : [
            {
              name  = "NEW_RELIC_NO_CONFIG_FILE"
              value = "true"
            },
            {
              name  = "NEW_RELIC_APP_NAME"
              value = var.new_relic_app_name
            },
            {
              name  = "NEW_RELIC_LICENSE_KEY"
              value = var.new_relic_license_key
            },
            {
              name  = "NEW_RELIC_DISTRIBUTED_TRACING_ENABLED"
              value = "true"
            },
            {
              name  = "NEW_RELIC_APPLICATION_LOGGING_FORWARDING_ENABLED"
              value = "true"
            }
          ]
        )
        secrets = [for key, value in var.secrets : {
          name      = key
          valueFrom = value
        }]
        logConfiguration = var.firelens_loki_host == null ? local.cloudwatch_log_configuration : local.loki_log_configuration
        healthCheck = var.health_check_command == null ? null : {
          command     = var.health_check_command
          interval    = 30
          retries     = 3
          timeout     = 5
          startPeriod = 30
        }
        }, var.firelens_loki_host == null ? {} : {
        dependsOn = [{
          containerName = "log_router"
          condition     = "START"
        }]
      })
    ],
    var.firelens_loki_host == null ? [] : [
      {
        name      = "log_router"
        image     = "public.ecr.aws/aws-observability/aws-for-fluent-bit:latest"
        essential = true
        firelensConfiguration = {
          type = "fluentbit"
          options = {
            "enable-ecs-log-metadata" = "true"
          }
        }
        logConfiguration = local.log_router_log_configuration
      }
    ]
  ))

  tags = var.tags

}

resource "aws_ecs_service" "this" {
  count = var.enabled ? 1 : 0

  name            = var.service_name
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnets
    security_groups  = var.security_groups
    assign_public_ip = var.assign_public_ip
  }

  dynamic "service_registries" {
    for_each = var.service_registry_arn == null ? [] : [var.service_registry_arn]
    content {
      registry_arn = service_registries.value
    }
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn == null ? [] : [1]
    content {
      target_group_arn = var.target_group_arn
      container_name   = var.service_name
      container_port   = var.container_port
    }
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = false
  }

  deployment_controller {
    type = "ECS"
  }

  health_check_grace_period_seconds = var.health_check_grace_period

  depends_on = [aws_ecs_task_definition.this]

}

resource "aws_appautoscaling_target" "this" {
  count = var.autoscaling_enabled ? 1 : 0

  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.this[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  count = var.autoscaling_enabled ? 1 : 0

  name               = "${var.service_name}-cpu-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.cpu_target_value
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}
