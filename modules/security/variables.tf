variable "project_name" {
  description = "Project name used in resource names and tags"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where security groups will be created"
  type        = string
}

variable "app_port" {
  description = "Port the application listens on inside ECS tasks"
  type        = number
  default     = 8080

  validation {
    condition     = var.app_port > 0 && var.app_port < 65536
    error_message = "app_port must be a valid TCP port between 1 and 65535."
  }
}

variable "db_port" {
  description = "Port the PostgreSQL database listens on"
  type        = number
  default     = 5432

  validation {
    condition     = var.db_port > 0 && var.db_port < 65536
    error_message = "db_port must be a valid TCP port between 1 and 65535."
  }
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to reach the ALB on HTTP/HTTPS"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}