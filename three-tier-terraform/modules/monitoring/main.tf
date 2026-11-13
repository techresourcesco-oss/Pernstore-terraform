resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = var.ecs_cpu_alarm_threshold
  alarm_description   = "ECS CPU utilization above threshold"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.frontend_service_name
  }

  treat_missing_data = "ignore"
  tags               = var.tags
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${var.project_name}-${var.environment}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "ALB has unhealthy targets"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  treat_missing_data = "ignore"
  tags               = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_cpu_alarm_threshold
  alarm_description   = "RDS CPU utilization above threshold"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  treat_missing_data = "ignore"
  tags               = var.tags
}
