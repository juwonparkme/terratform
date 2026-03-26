resource "aws_lb" "this" {
  name                       = substr("${local.name_prefix}-alb", 0, 32)
  load_balancer_type         = "application"
  internal                   = false
  security_groups            = [aws_security_group.alb.id]
  subnets                    = local.public_subnet_ids
  enable_deletion_protection = var.alb_deletion_protection
  idle_timeout               = 30

  tags = local.tags
}

resource "aws_lb_target_group" "lambda" {
  count = var.lambda_size

  name        = local.target_group_names[count.index]
  target_type = "lambda"

  health_check {
    enabled  = true
    path     = "/v${count.index}/health"
    interval = 35
    timeout  = 30
  }

  tags = local.tags
}

resource "aws_lb_target_group_attachment" "lambda" {
  count = var.lambda_size

  target_group_arn = aws_lb_target_group.lambda[count.index].arn
  target_id        = aws_lambda_function.proxy[count.index].arn

  depends_on = [aws_lambda_permission.alb]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = local.https_enabled ? [1] : []
    content {
      type = "redirect"

      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = local.https_enabled ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.lambda[0].arn
    }
  }
}

resource "aws_lb_listener" "https" {
  count = local.https_enabled ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lambda[0].arn
  }
}

resource "aws_lb_listener_rule" "http_lambda" {
  count = local.https_enabled ? 0 : var.lambda_size

  listener_arn = aws_lb_listener.http.arn
  priority     = count.index + 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lambda[count.index].arn
  }

  condition {
    path_pattern {
      values = ["/v${count.index}/*"]
    }
  }
}

resource "aws_lb_listener_rule" "https_lambda" {
  count = local.https_enabled ? var.lambda_size : 0

  listener_arn = aws_lb_listener.https[0].arn
  priority     = count.index + 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lambda[count.index].arn
  }

  condition {
    path_pattern {
      values = ["/v${count.index}/*"]
    }
  }
}
