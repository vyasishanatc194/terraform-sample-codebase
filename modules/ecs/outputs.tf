output "execution_role_arn" {
  value = "${aws_iam_role.ecsTaskExecutionRole.arn}"
}

output "task_role_arn" {
  value = "${aws_iam_role.app_role.arn}"
}

output "cluster_id" {
  value = "${aws_ecs_cluster.service.id}"
}

output "cluster_name" {
  value = "${aws_ecs_cluster.service.name}"
}

output "repository_urls" {
  value = aws_ecr_repository.repo.*.repository_url
  description = "List of repository urls"
}

output "cloudwatch_name" {
  value = "${aws_cloudwatch_log_group.task.name}"
}