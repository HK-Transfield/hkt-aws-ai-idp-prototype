/*
Name:     Application Load Balancer Module
Project:  AWS Generative AI Backed IDP Solution
Author:   HK Transfield, 2025

This module configures an Application Load Balancer (ALB) for a given application. 
It includes security groups, target groups, and listeners for HTTP and HTTPS 
traffic. The module also sets up a listener rule to forward traffic to the 
target group based on the specified path pattern.
*/

################################################################################
# LOAD BALANCER
################################################################################

locals {
  alb_name = "${var.app_name}-alb"
}

resource "aws_lb" "this" {
  name               = local.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.this.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false

  tags = merge(
    var.tags,
    {
      Name = local.alb_name
    }
  )
}

resource "aws_lb_target_group" "this" {
  name        = "${local.alb_name}-tg"
  port        = 8501
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    port                = "traffic-port"
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.alb_name}-tg"
    }
  )
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn

    redirect {
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = aws_acm_certificate.this.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_acm_certificate" "this" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = merge(
    var.tags,
    {
      Name = "${local.alb_name}-cert"
    }
  )
}

################################################################################
# SECURITY GROUP
################################################################################

resource "aws_security_group" "this" {
  name        = "${local.alb_name}-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id
}


resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.this.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.allowed_ingress_ip
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.this.id
  from_port         = 443
  to_port           = 443
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