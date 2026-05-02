variable "aws_region" {
  description = "aws region for the all resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "cidr for the main VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "aws-cloudnative-webapp"
}

variable "environment" {
  description = "Deployment environment (dev, staging, or prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "container_image" {
  description = "Container image URI to run in ECS tasks (e.g., nginx:latest, account.dkr.ecr.us-east-1.amazonaws.com/myapp:v1)"
  type        = string
  default     = "nginx:latest"
}