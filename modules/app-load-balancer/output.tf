output "alb_dns_name" {
  value       = aws_lb.this.dns_name
  description = "DNS name of the load balancer"
}

output "target_group_arn" {
  value       = aws_lb_target_group.this.arn
  description = "ARN of the target group"
}

output "alb_security_group_id" {
  value       = aws_security_group.this.id
  description = "Security group ID for the ALB"
}