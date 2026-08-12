output "github_actions_role_arn" {
  description = "IAM role ARN used by GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}

output "ecr_repository" {
  description = "ECR repository"
  value       = "todo-app"
}