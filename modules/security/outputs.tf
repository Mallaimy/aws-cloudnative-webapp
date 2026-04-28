output "alb_sg_id" {
  description = "ID of the ALB security group that allow HTTP/HTTPS requests"
  value       = aws_security_group.alb.id
}

output "ecs_sg_id" {
  description = "ID of the ECS security group that allow ALB to request the ECS Tasks"
  value       = aws_security_group.ecs.id
}

output "db_sg_id" {
  description = "ID of the Database security group that allow ECS to request the DB"
  value       = aws_security_group.db.id
}
