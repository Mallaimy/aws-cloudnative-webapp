variable "project_name" {
  description = "Project name used for resource naming and tags"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in 'owner/repo' format (e.g., 'Mallaimy/aws-cloudnative-webapp'); used in the OIDC trust policy to scope which repo can assume the role"
  type        = string
}

variable "task_execution_role_arn" {
  description = "ARN of the ECS task execution role; used to scope iam:PassRole permissions in the workflow's IAM policy"
  type        = string
}