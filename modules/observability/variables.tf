variable "project_name" {
  description = "Name of the project, required"
  type        = string
}

variable "cluster_name" {
  description = "Cluster name where the Cloudwatch pulls metrics"
  type        = string
}

variable "service_name" {
  description = "service name that manage ECS tasks "
  type        = string
}

variable "region" {
  description = "AWS region where metrics are published"
  type        = string
  default     = "us-east-1"
}

variable "alb_arn_suffix" {
  description = "Load Balancer arn suffix"
  type        = string
}

variable "db_instance_identifier" {
  description = "Database indentifier instance name"
  type        = string
}
