# ── VPC ───────────────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (where RDS lives)"
  value       = aws_subnet.private[*].id
}

# ── Security Groups ───────────────────────────────────────────────────────────

output "app_security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.app.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

# ── RDS ───────────────────────────────────────────────────────────────────────

output "rds_endpoint" {
  description = "Connection endpoint for the RDS instance (host:port)"
  value       = aws_db_instance.main.endpoint
}

output "rds_host" {
  description = "Hostname of the RDS instance"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "Port of the RDS instance"
  value       = aws_db_instance.main.port
}

output "rds_db_name" {
  description = "Name of the PostgreSQL database"
  value       = aws_db_instance.main.db_name
}

output "rds_instance_id" {
  description = "Identifier of the RDS instance"
  value       = aws_db_instance.main.id
}

output "database_url" {
  description = "Full DATABASE_URL connection string (password hidden)"
  value       = "postgresql://${var.db_username}:****@${aws_db_instance.main.endpoint}/${var.db_name}"
  sensitive   = true
}

# ── ECR ───────────────────────────────────────────────────────────────────────

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.blacklist.repository_url
}

# ── ECS ───────────────────────────────────────────────────────────────────────

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.blacklist.name
}

# ── ALB ───────────────────────────────────────────────────────────────────────

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

# ── CodeBuild ─────────────────────────────────────────────────────────────────

output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = aws_codebuild_project.blacklist.name
}

output "codebuild_project_arn" {
  description = "ARN of the CodeBuild project"
  value       = aws_codebuild_project.blacklist.arn
}

# ── CodePipeline ──────────────────────────────────────────────────────────────

output "codepipeline_name" {
  description = "Name of the CodePipeline"
  value       = var.enable_ci_pipeline ? aws_codepipeline.app_pipeline[0].name : null
}

output "codepipeline_arn" {
  description = "ARN of the CodePipeline"
  value       = var.enable_ci_pipeline ? aws_codepipeline.app_pipeline[0].arn : null
}
