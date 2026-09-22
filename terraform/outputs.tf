output "alb_dns_name" {
  description = "Public URL of the app"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

output "github_actions_role_arn" {
  description = "Set this as the AWS_ROLE_ARN secret/variable in GitHub"
  value       = aws_iam_role.github_actions_deploy.arn
}
