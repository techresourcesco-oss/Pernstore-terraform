data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "${var.project_name}-${var.environment}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "frontend_task" {
  name               = "${var.project_name}-${var.environment}-frontend-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  tags = var.tags
}

resource "aws_iam_role" "backend_task" {
  name               = "${var.project_name}-${var.environment}-backend-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  tags = var.tags
}

resource "aws_iam_policy" "secrets_access" {
  name = "${var.project_name}-${var.environment}-secrets-read"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = [
        "arn:aws:secretsmanager:${var.aws_region}:${var.account_id}:secret:${var.project_name}/${var.environment}/*",
        "arn:aws:secretsmanager:${var.aws_region}:${var.account_id}:secret:rds!db-*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_secrets" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

resource "aws_iam_role_policy_attachment" "frontend_task_secrets" {
  role       = aws_iam_role.frontend_task.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

resource "aws_iam_role_policy_attachment" "backend_task_secrets" {
  role       = aws_iam_role.backend_task.name
  policy_arn = aws_iam_policy.secrets_access.arn
}
