output "db_endpoint" {
  description = "Connection endpoint for the database (host:port)"
  value       = aws_db_instance.main.endpoint
}

output "db_address" {
  description = "DNS address of the database (host only, no port)"
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "Port the database listens on"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Name of the PostgreSQL database created"
  value       = aws_db_instance.main.db_name
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.db.arn
}

output "db_secret_name" {
  description = "Name of the Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.db.name
}