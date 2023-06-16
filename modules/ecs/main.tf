resource "aws_ecs_cluster" "service" {
  name = "${var.name}-cluster"

  setting {
    name = "containerInsights"
    value=var.container_insights_enabled
  }
}

resource "aws_ecr_repository" "repo" {
  count = length(var.repo)
  name = var.repo[count.index]
  lifecycle {
    prevent_destroy = true
  }
}


# Policies for ecsExecutionRole
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_policy" {
  statement {
    actions = [
      "ssm:*",
      "secretsmanager:*",
      "sqs:*",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "${var.name}-ecs"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

# assigns the app policy
resource "aws_iam_role_policy" "ecsTaskExecutionRole_policy" {
  name   = "ecsTaskExecutionRolePolicy-${var.name}"
  role   = aws_iam_role.ecsTaskExecutionRole.id
  policy = data.aws_iam_policy_document.ecs_policy.json
}


# creates an application role that the container/task runs as
data "aws_iam_policy_document" "app_policy" {
  statement {
    actions = var.policies
    resources = [
     "*"
    ]
  }
}

resource "aws_iam_role" "app_role" {
  name               = "${var.name}-app"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}
# assigns the app policy
resource "aws_iam_role_policy" "app_policy" {
  name   = "ecsAppRolePolicy-${var.name}"
  role   = aws_iam_role.app_role.id
  policy = data.aws_iam_policy_document.app_policy.json
}

resource "aws_cloudwatch_log_group" "task" {
  name              = "/aws/ecs/exii/${var.name}"
  retention_in_days = 7
  tags = {
    Name = var.name
  }
}
