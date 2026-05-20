# ── Application Load Balancer ─────────────────────────────────────────────────

resource "aws_lb" "main" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = merge(local.tags, { Name = "${local.name_prefix}-alb" })
}

# ── Target Groups (Blue / Green) ──────────────────────────────────────────────

resource "aws_lb_target_group" "blue" {
  name     = "${local.name_prefix}-tg"
  port     = var.container_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-tg" })
}

resource "aws_lb_target_group" "green" {
  name     = "${local.name_prefix}-tg-green"
  port     = var.container_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-tg-green" })
}

# ── Listeners ─────────────────────────────────────────────────────────────────

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-listener-prod" })

  lifecycle {
    ignore_changes = [default_action]
  }
}

# Test listener used by CodeDeploy to validate the green environment before swap
resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.main.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-listener-test" })

  lifecycle {
    ignore_changes = [default_action]
  }
}
