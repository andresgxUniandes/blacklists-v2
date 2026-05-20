# ── SSM SecureString parameters for application secrets ──────────────────────
# These are read by ECS tasks at runtime via the secrets[] block in the task def.

resource "aws_ssm_parameter" "database_url" {
  name  = "/${local.name_prefix}/DATABASE_URL"
  type  = "SecureString"
  value = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.main.address}:5432/${var.db_name}"

  tags = merge(local.tags, { Name = "/${local.name_prefix}/DATABASE_URL" })
}

resource "aws_ssm_parameter" "jwt_secret_key" {
  name  = "/${local.name_prefix}/JWT_SECRET_KEY"
  type  = "SecureString"
  value = var.jwt_secret_key

  tags = merge(local.tags, { Name = "/${local.name_prefix}/JWT_SECRET_KEY" })
}

resource "aws_ssm_parameter" "auth_username" {
  name  = "/${local.name_prefix}/AUTH_USERNAME"
  type  = "String"
  value = var.auth_username

  tags = merge(local.tags, { Name = "/${local.name_prefix}/AUTH_USERNAME" })
}

resource "aws_ssm_parameter" "auth_password" {
  name  = "/${local.name_prefix}/AUTH_PASSWORD"
  type  = "SecureString"
  value = var.auth_password

  tags = merge(local.tags, { Name = "/${local.name_prefix}/AUTH_PASSWORD" })
}
