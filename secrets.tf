# Use deploy-secrets.py to populate this secrets

data "aws_secretsmanager_secret" "database_password" {
  name = "/exii/database/password"
}