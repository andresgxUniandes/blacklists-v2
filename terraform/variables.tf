variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
  default     = "blacklist"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# ── Networking ────────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the two private subnets (RDS requires at least two AZs)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets (application layer)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

# ── RDS ───────────────────────────────────────────────────────────────────────

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "blacklistdb"
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "db_password" {
  description = "Master password for the RDS instance (min 8 chars)"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.3"
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = false
}

variable "db_deletion_protection" {
  description = "Prevent accidental deletion of the RDS instance"
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "Number of days to retain automated backups (0 disables backups)"
  type        = number
  default     = 0
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot when destroying the RDS instance"
  type        = bool
  default     = true
}

# ── Application access ────────────────────────────────────────────────────────

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to RDS (e.g. bastion or CI runner IP)"
  type        = list(string)
  default     = []
}

# ── ECS on EC2 ────────────────────────────────────────────────────────────────

variable "ecs_instance_type" {
  description = "EC2 instance type for ECS container instances"
  type        = string
  default     = "t3.micro"
}

variable "ecs_min_instances" {
  description = "Minimum number of EC2 instances in the ECS Auto Scaling group"
  type        = number
  default     = 1
}

variable "ecs_max_instances" {
  description = "Maximum number of EC2 instances in the ECS Auto Scaling group"
  type        = number
  default     = 3
}

variable "ecs_desired_instances" {
  description = "Desired number of EC2 instances in the ECS Auto Scaling group"
  type        = number
  default     = 1
}

variable "ecs_task_desired_count" {
  description = "Desired number of ECS task instances running"
  type        = number
  default     = 1
}

variable "ecs_task_cpu" {
  description = "CPU units reserved for the ECS task (1 vCPU = 1024 units)"
  type        = number
  default     = 256
}

variable "ecs_task_memory" {
  description = "Memory (MB) reserved for the ECS task"
  type        = number
  default     = 512
}

variable "container_port" {
  description = "Port the application container listens on"
  type        = number
  default     = 5000
}

# ── Application Secrets ───────────────────────────────────────────────────────

variable "jwt_secret_key" {
  description = "Secret key used to sign JWT tokens"
  type        = string
  default     = "change-this-secret"
  sensitive   = true
}

variable "auth_username" {
  description = "Username for API authentication"
  type        = string
  default     = "admin"
}

variable "auth_password" {
  description = "Password for API authentication"
  type        = string
  default     = "admin"
  sensitive   = true
}

# ── New Relic ─────────────────────────────────────────────────────────────────

variable "new_relic_app_name" {
  description = "Application name shown in New Relic"
  type        = string
  default     = "blacklist-app"
}

variable "new_relic_license_key_ssm_path" {
  description = "SSM Parameter Store path for the New Relic license key"
  type        = string
  default     = "/NEW_RELIC_LICENSE_KEY"
}

# ── CodeBuild ─────────────────────────────────────────────────────────────────

variable "github_repo_url" {
  description = "GitHub repository HTTPS URL used as CodeBuild source (e.g. https://github.com/owner/repo)"
  type        = string
}
