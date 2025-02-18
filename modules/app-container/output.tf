output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.streamlit.dns_name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.streamlit.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.streamlit.name
}

output "cloudwatch_log_group" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.streamlit.name
}