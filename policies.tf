locals {
    policies = {
        default = [
            "ecs:DescribeClusters",
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            # ECS tasks to upload logs to CloudWatch
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            # SSM
            "ssm:*",
            "sqs:*",
            "s3:*",
            "secretsmanager:*"
        ],
        frontend = [
            "ecs:DescribeClusters",
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            # ECS tasks to upload logs to CloudWatch
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            # SSM
            "ssm:*",
            "sqs:*",
            "s3:*",
            "secretsmanager:*"
        ]
    }
}