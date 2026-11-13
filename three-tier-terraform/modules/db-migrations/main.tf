resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name}-db-migrations"
  retention_in_days = 30
  tags              = var.tags
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.name}-db-migrations"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "${var.name}-db-migrations"
      image     = var.image
      essential = true
      command   = ["node", "scripts/migrate.js", "up"]
      environment = [
        {
          name  = "POSTGRES_HOST"
          value = var.db_host
        },
        {
          name  = "POSTGRES_PORT"
          value = tostring(var.db_port)
        },
        {
          name  = "POSTGRES_USER"
          value = var.db_username
        },
        {
          name  = "POSTGRES_DB"
          value = var.db_name
        },
        {
          name  = "NODE_ENV"
          value = "production"
        }
      ]
      secrets = [
        {
          name      = "POSTGRES_PASSWORD"
          valueFrom = "${var.db_password_secret_arn}:password::"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "migration"
        }
      }
    }
  ])

  tags = var.tags
}

resource "terraform_data" "run" {
  triggers_replace = [
    aws_ecs_task_definition.this.arn,
    var.db_host
  ]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = <<-EOT
      $ErrorActionPreference = 'Stop'
      $taskArn = aws ecs run-task --region "${var.aws_region}" --cluster "${var.cluster_name}" --task-definition "${aws_ecs_task_definition.this.arn}" --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[${join(",", var.subnet_ids)}],securityGroups=[${var.security_group_id}],assignPublicIp=DISABLED}" --query "tasks[0].taskArn" --output text
      if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($taskArn) -or $taskArn -eq "None") { throw "Could not start the database migration task." }

      aws ecs wait tasks-stopped --region "${var.aws_region}" --cluster "${var.cluster_name}" --tasks $taskArn
      if ($LASTEXITCODE -ne 0) { throw "Timed out waiting for the database migration task." }

      $exitCode = aws ecs describe-tasks --region "${var.aws_region}" --cluster "${var.cluster_name}" --tasks $taskArn --query "tasks[0].containers[0].exitCode" --output text
      if ($LASTEXITCODE -ne 0) { throw "Could not read the database migration task result." }
      if ("$exitCode" -ne "0") {
        $reason = aws ecs describe-tasks --region "${var.aws_region}" --cluster "${var.cluster_name}" --tasks $taskArn --query "tasks[0].stoppedReason" --output text
        throw "Database migration task failed with exit code $exitCode. $reason"
      }
    EOT
  }
}
