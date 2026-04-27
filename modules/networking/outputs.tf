output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID of the created VPC"

}

output "vpc_cidr" {
  value       = aws_vpc.main.cidr_block
  description = "CIDR block of the VPC"
}

output "public_subnet_ids" {
  value       = [for public in aws_subnet.public : public.id]
  description = "List of IDs for the public subnets"
}

output "private_subnet_ids" {
  value       = [for private in aws_subnet.private : private.id]
  description = "List of IDs for the private subnets"
}

output "db_subnet_ids" {
  value       = [for db in aws_subnet.db : db.id]
  description = "List of IDs for the db subnets"
}

output "availability_zones" {
  value       = local.azs
  description = "List of AZs used for the project"
}