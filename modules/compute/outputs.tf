output "cluster_id" {
  description = "ID of the cluster where ecs resources are created"
  value       = aws_ecs_cluster.main.id
}

output "log_group_name" {
  description = "Name of the CloudWatch log group where ECS task and container logs are written"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "task_execution_role_arn" {
  description = "ARN of the IAM role used by ECS to pull images, write logs, and fetch secrets"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer (use this URL to reach the application)"
  value       = aws_lb.main.dns_name
}

output "target_group_arn" {
  description = "ARN of the target group where ECS tasks register"
  value       = aws_lb_target_group.app.arn
}

output "ecr_repository_url" {
  description = "URL of the ECR repository for the application"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.app.name
}