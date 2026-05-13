output "dashbord_name" {
  description = "Dashborad name"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashbord_arn" {
  description = "Dashborad arn"
  value       = aws_cloudwatch_dashboard.main.dashboard_arn
}
