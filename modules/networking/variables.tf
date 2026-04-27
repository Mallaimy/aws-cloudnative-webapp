variable "project_name" {
  description = "Name of the project, required"
  type        = string

}

variable "vpc_cidr" {
  description = "cidr for the main VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to span. Determines how many subnets per tier are created."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 4
    error_message = "az_count must be between 2 and 4."
  }

}