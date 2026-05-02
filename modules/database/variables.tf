variable "project_name" {
  description = "Project name used for resource naming and tags"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC that contains the DB resources"
  type        = string
}

variable "db_subnet_ids" {
  description = "List of subnet IDs where the database can be deployed"
  type        = list(string)
}

variable "db_sg_id" {
  description = "ID of the security group attached to the database"
  type        = string
}

variable "db_name" {
  description = "PostgreSQL database name to create on the instance"
  type        = string
  default     = "appdb"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]*$", var.db_name))
    error_message = "PostgreSQL database names must contain only lowercase letters, digits, and underscores, and cannot start with a digit."
  }

}

variable "db_username" {
  description = "Master username for PostgreSQL (admin account)"
  type        = string
  default     = "dbadmin"
}

variable "db_instance_class" {
  description = "RDS instance class (e.g., db.t3.micro, db.t3.small)"
  type        = string
  default     = "db.t3.micro"
}

variable "db_engine_version" {
  description = "PostgreSQL engine version (e.g., 15.7)"
  type        = string
  default     = "15.7"

}