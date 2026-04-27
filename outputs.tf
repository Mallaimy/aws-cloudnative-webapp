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