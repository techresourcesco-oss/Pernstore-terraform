resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.subnet_ids

  enable_deletion_protection = var.deletion_protection

  tags = merge(var.tags, {
    Name = "${var.name}-alb"
  })
}

resource "aws_lb_target_group" "frontend" {
  name        = "${var.name}-frontend-tg"
  port        = var.frontend_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = var.frontend_health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 5
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    port                = var.frontend_port
    protocol            = "HTTP"
  }

  tags = merge(var.tags, {
    Name = "${var.name}-frontend-tg"
  })
}

resource "aws_lb_target_group" "backend" {
  name        = "${var.name}-backend-tg"
  port        = var.backend_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = var.backend_health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 5
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    port                = var.backend_port
    protocol            = "HTTP"
  }

  tags = merge(var.tags, {
    Name = "${var.name}-backend-tg"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = local.https_enabled ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = local.https_enabled ? [1] : []

      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    dynamic "forward" {
      for_each = local.https_enabled ? [] : [1]

      content {
        target_group {
          arn = aws_lb_target_group.frontend.arn
        }
      }
    }
  }
}

locals {
  https_enabled    = var.certificate_arn != ""
  api_listener_arn = local.https_enabled ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
}

resource "aws_lb_listener" "https" {
  count             = local.https_enabled ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = local.api_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}
