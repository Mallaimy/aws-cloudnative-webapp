output "github_actions_role_arn" {
  description = "ARN of the IAM role that GitHub Actions assumes via OIDC; reference this in workflow files as the role-to-assume value"
  value       = aws_iam_role.github_actions.arn
}