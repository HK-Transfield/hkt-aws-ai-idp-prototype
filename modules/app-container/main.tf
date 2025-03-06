/*
Name:     Application Container Module
Project:  AWS Generative AI Backed IDP Solution
Author:   HK Transfield, 2025

This module configures an AWS Fargate serverless compute engine intended to 
run a frontend Streamlit application.
*/

data "aws_region" "current" {}

################################################################################
# APPLICATION CONTAINERES
################################################################################

resource "aws_ecs_cluster" "this" {
  name = "${var.app_name}-cluster"
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.app_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([{
    name  = var.app_name
    image = var.docker_image
    environment = [{
      name  = "BUCKET_NAME"
      value = var.bucket_name
    }]
    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.this.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = merge(
    var.tags,
    {
      "Name" = var.app_name
    },
  )
}

resource "aws_ecs_service" "this" {
  name            = var.app_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.this.id]
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = var.app_name
    container_port   = var.container_port
  }

  tags = merge(
    var.tags,
    {
      "Name" = var.app_name
    },
  )
}

################################################################################
# APPLICATION AUTO SCALING
################################################################################

resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = merge(
    var.tags,
    {
      "Name" = var.app_name
    },
  )
}

resource "aws_appautoscaling_policy" "ecs" {
  name               = "${var.app_name}-scale-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 70
  }
}

################################################################################
# IAM ENTITIES
################################################################################

locals {
  iam_role_name = "${var.app_name}-ecs-execution"
}

resource "aws_iam_role" "ecs_execution" {
  name = local.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      "Name" = local.iam_role_name
    },
  )
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

################################################################################
# MONITORING AND LOGGING
################################################################################

locals {
  log_group_name = "/ecs/${var.app_name}"
}

resource "aws_cloudwatch_log_group" "this" {
  name              = local.log_group_name
  retention_in_days = var.retention_in_days

  tags = merge(
    var.tags,
    {
      "Name" = local.log_group_name
    },
  )
}

################################################################################
# SECURITY GROUPS
################################################################################

locals {
  sg_name = "${var.app_name}-sg"
}

resource "aws_security_group" "this" {
  name        = local.sg_name
  description = "Security group for Streamlit application"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      "Name" = local.sg_name
    },
  )
}

resource "aws_vpc_security_group_ingress_rule" "allow_tcp" {
  security_group_id = aws_security_group.this.id
  from_port         = var.container_port
  to_port           = var.container_port
  ip_protocol       = "tcp"
  cidr_ipv4         = var.allowed_ingress_ip
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound" {
  security_group_id = aws_security_group.this.id
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = var.allowed_egress_ip
}