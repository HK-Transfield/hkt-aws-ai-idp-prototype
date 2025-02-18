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
}

resource "aws_ecs_service" "this" {
  name            = var.app_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.streamlit.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.streamlit.arn
    container_name   = var.app_name
    container_port   = var.container_port
  }
}

################################################################################
# IAM ENTITIES
################################################################################

resource "aws_iam_role" "ecs_execution" {
  name = "${var.app_name}-ecs-execution"

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
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

################################################################################
# MONITORING AND LOGGING
################################################################################

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.app_name}"
  retention_in_days = 30
}

resource "aws_security_group" "streamlit" {
  name        = "${var.app_name}-sg"
  description = "Security group for Streamlit application"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "streamlit" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids
}

resource "aws_security_group" "alb" {
  name        = "${var.app_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "streamlit" {
  name        = "${var.app_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 60
    interval            = 300
    path                = "/"
  }
}

resource "aws_lb_listener" "streamlit" {
  load_balancer_arn = aws_lb.streamlit.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.streamlit.arn
  }
}


