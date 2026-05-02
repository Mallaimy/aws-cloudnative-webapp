output "vpc_id" {
  description = "ID of the VPC created by the networking module"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "List of IDs for the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of IDs for the private subnets"
  value       = module.networking.private_subnet_ids
}

output "db_subnet_ids" {
  description = "List of IDs for the database subnets"
  value       = module.networking.db_subnet_ids
}

output "alb_sg_id" {
  description = "ID of the ALB security group"
  value       = module.security.alb_sg_id
}

output "ecs_sg_id" {
  description = "ID of the ECS security group"
  value       = module.security.ecs_sg_id
}

output "db_sg_id" {
  description = "ID of the database security group"
  value       = module.security.db_sg_id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer (use this URL to reach the application)"
  value       = module.compute.alb_dns_name
}

output "db_endpoint" {
  description = "Connection endpoint for the database"
  value       = module.database.db_endpoint
}

output "db_secret_arn" {
  description = "ARN of the database credentials secret"
  value       = module.database.db_secret_arn
}