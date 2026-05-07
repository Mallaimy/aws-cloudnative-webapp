variable "project_name" {
  description = "Project name used for resource naming and tags"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where compute resources will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where the ALB will be deployed"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs where ECS tasks will run"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "ID of the security group for the ALB"
  type        = string
}

variable "ecs_sg_id" {
  description = "ID of the security group for ECS tasks"
  type        = string
}

variable "app_port" {
  description = "Port the application listens on inside the container"
  type        = number
  default     = 8080

  validation {
    condition     = var.app_port > 0 && var.app_port < 65536
    error_message = "The port number should be between 1 and 65535"
  }
}

variable "container_image" {
  description = "Container image URL to run in ECS tasks (e.g., nginx:latest)"
  type        = string
}

variable "db_host" {
  description = "Database host address (DNS name only, no port)"
  type        = string
}

variable "db_port" {
  description = "Database port"
  type        = number
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing DB credentials JSON"
  type        = string
}

