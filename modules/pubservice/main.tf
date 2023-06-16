# Security group for the service
resource "aws_security_group" "ecs" {
  name        = "${var.name}-ecs"
  description = "Allow traffic for ecs"
  vpc_id      = var.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = concat(var.vpc.public_subnets_cidr_blocks,var.vpc.private_subnets_cidr_blocks)
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = concat(var.vpc.public_subnets_cidr_blocks,var.vpc.private_subnets_cidr_blocks)
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.vpc.database_subnets_cidr_blocks
  }

  egress {
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 587
    to_port     = 587
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


resource "aws_ecs_task_definition" "task" {
  family                   = "${var.name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.execution_role
  task_role_arn            = var.task_role
  container_definitions    = var.container_definitions
  tags = var.tags
}

resource "aws_ecs_service" "app" {
  name            = "${var.name}-service"
  cluster         = var.cluster_id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = var.desiderable_count
  health_check_grace_period_seconds = 120

  network_configuration {
    subnets = var.vpc.public_subnets
    security_groups = ["${aws_security_group.ecs.id}"]
    assign_public_ip = true
  }

  load_balancer {
   target_group_arn = var.target_arn
   container_name = var.container_name
   container_port = 80
  }

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }
}
