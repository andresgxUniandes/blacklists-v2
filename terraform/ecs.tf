# ── ECS-Optimized AMI ─────────────────────────────────────────────────────────

data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-ecs-hvm-*-x86_64"]
  }
}

# ── ECS Cluster ───────────────────────────────────────────────────────────────

resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-cluster" })
}

# ── Launch Template for EC2 instances ─────────────────────────────────────────

resource "aws_launch_template" "ecs" {
  name_prefix   = "${local.name_prefix}-ecs-lt-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = var.ecs_instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance.name
  }

  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
    echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.tags, { Name = "${local.name_prefix}-ecs-node" })
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-ecs-lt" })
}

# ── Auto Scaling Group ────────────────────────────────────────────────────────

resource "aws_autoscaling_group" "ecs" {
  name                = "${local.name_prefix}-ecs-asg"
  min_size            = var.ecs_min_instances
  max_size            = var.ecs_max_instances
  desired_capacity    = var.ecs_desired_instances
  vpc_zone_identifier = aws_subnet.public[*].id

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  protect_from_scale_in = true

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

# ── Capacity Provider ─────────────────────────────────────────────────────────

resource "aws_ecs_capacity_provider" "main" {
  name = "${local.name_prefix}-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 80
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 10
    }
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-cp" })
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.main.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 1
    base              = 1
  }
}

# ── CloudWatch Log Group ──────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = 7

  tags = merge(local.tags, { Name = "/ecs/${local.name_prefix}" })
}

# ── Task Definition ───────────────────────────────────────────────────────────

resource "aws_ecs_task_definition" "blacklist" {
  family                = "${local.name_prefix}-task"
  requires_compatibilities = ["EC2"]
  network_mode          = "bridge"
  cpu                   = var.ecs_task_cpu
  memory                = var.ecs_task_memory
  execution_role_arn    = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([{
    name      = "app-ecr-blacklist"
    image     = "${aws_ecr_repository.blacklist.repository_url}:latest"
    essential = true

    portMappings = [{
      containerPort = var.container_port
      hostPort      = 0
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "DATABASE_URL"
        value = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.main.address}:5432/${var.db_name}"
      },
      {
        name  = "JWT_SECRET_KEY"
        value = var.jwt_secret_key
      },
      {
        name  = "AUTH_USERNAME"
        value = var.auth_username
      },
      {
        name  = "AUTH_PASSWORD"
        value = var.auth_password
      },
      {
        name  = "NEW_RELIC_APP_NAME"
        value = var.new_relic_app_name
      },
      {
        name  = "NEW_RELIC_LOG"
        value = "stdout"
      },
      {
        name  = "NEW_RELIC_LOG_LEVEL"
        value = "info"
      },
      {
        name  = "NEW_RELIC_DISTRIBUTED_TRACING_ENABLED"
        value = "true"
      }
    ]

    secrets = [{
      name      = "NEW_RELIC_LICENSE_KEY"
      valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.new_relic_license_key_ssm_path}"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = merge(local.tags, { Name = "${local.name_prefix}-task" })
}

# ── ECS Service ───────────────────────────────────────────────────────────────

resource "aws_ecs_service" "blacklist" {
  name            = "${local.name_prefix}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.blacklist.arn
  desired_count   = var.ecs_task_desired_count
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app-ecr-blacklist"
    container_port   = var.container_port
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  ordered_placement_strategy {
    type  = "binpack"
    field = "memory"
  }

  depends_on = [
    aws_lb_listener.http,
    aws_iam_role_policy_attachment.ecs_task_execution,
  ]

  tags = merge(local.tags, { Name = "${local.name_prefix}-service" })
}
