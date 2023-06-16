data "aws_secretsmanager_secret_version" "database_password" {
  secret_id = var.database_password
}


resource "aws_security_group" "allow_db" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_db_instance" "main" {
  identifier = "${var.name}-rds"
  allocated_storage = "10"
  db_subnet_group_name = var.database_subnet_group
  instance_class = "db.t2.micro"
  storage_type = "gp2"
  engine = "postgres"
  engine_version = "11.13"

  name = var.database_name
  username = var.database_username
  password = data.aws_secretsmanager_secret_version.database_password.secret_string

  publicly_accessible = true
  vpc_security_group_ids = ["${aws_security_group.allow_db.id}"]

  skip_final_snapshot = true
  # allow_major_version_upgrade = "Optional"
  apply_immediately = true

  # auto_minor_version_upgrade = "Optional"
  # availability_zone = "Optional"
  # backup_retention_period = "Optional"
  # character_set_name = "Optional"

  # deletion_protection = "Optional"
  # domain = "Optional"
  # domain_iam_role_name = "Optional"
  # enabled_cloudwatch_logs_exports = "Optional"


  # final_snapshot_identifier = "Optional"
  # iam_database_authentication_enabled = "Optional"
  # identifier = "Optional"
  # identifier_prefix = "Optional"

  # iops = "Optional"
  # kms_key_id = "Optional"
  # license_model = "Optional"
  # monitoring_interval = "Optional"
  # monitoring_role_arn = "Optional"

  # option_group_name = "Optional"
  # parameter_group_name = "Optional"

  # port = "Optional"

  # skip_final_snapshot = "Optional"

  # tags = "Optional"
  # timezone = "Optional"

  # s3_import = "Optional"

  # Database Deletion Protection
  deletion_protection = false
  backup_retention_period = 7

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    "Name" = var.name
  }
}