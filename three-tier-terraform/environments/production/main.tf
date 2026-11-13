terraform {
  required_version = ">= 1.5.0"

  # Uncomment after creating the state bucket and filling in backend.hcl.
  # backend "s3" {
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Tier        = var.tier
  }
  frontend_repository_url = data.aws_ecr_repository.frontend.repository_url
  backend_repository_url  = data.aws_ecr_repository.backend.repository_url
}

resource "random_password" "app_secret" {
  length  = 32
  special = true
}

resource "random_password" "refresh_secret" {
  length  = 32
  special = true
}

resource "aws_secretsmanager_secret" "app" {
  name_prefix = "${var.project_name}/${var.environment}/app-"
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id
  secret_string = jsonencode({
    SECRET         = random_password.app_secret.result
    REFRESH_SECRET = random_password.refresh_secret.result
  })
}

module "networking" {
  source = "../../modules/networking"

  name                 = "${var.project_name}-${var.environment}"
  aws_region           = var.aws_region
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnets       = var.public_subnets
  private_app_subnets  = var.private_app_subnets
  private_data_subnets = var.private_data_subnets
  enable_nat_gateway   = var.enable_nat_gateway
  tags                 = local.tags
}

module "security_groups" {
  source = "../../modules/security-groups"

  name          = "${var.project_name}-${var.environment}"
  vpc_id        = module.networking.vpc_id
  frontend_port = var.frontend_container_port
  backend_port  = var.backend_container_port
  tags          = local.tags
}

data "aws_ecr_repository" "frontend" {
  name = "store/frontend"
}

data "aws_ecr_repository" "backend" {
  name = "store/backend"
}

module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  account_id   = data.aws_caller_identity.current.account_id
  tags         = local.tags
}

module "rds" {
  source = "../../modules/rds"

  name                         = "${var.project_name}-${var.environment}"
  db_name                      = var.database_name
  db_username                  = var.database_username
  engine_version               = var.db_engine_version
  instance_class               = var.db_instance_class
  allocated_storage            = var.db_allocated_storage
  max_allocated_storage        = var.db_max_allocated_storage
  subnet_ids                   = module.networking.private_data_subnet_ids
  vpc_security_group_ids       = [module.security_groups.rds_security_group_id]
  multi_az                     = var.rds_multi_az
  backup_retention_period      = var.backup_retention_period
  deletion_protection          = var.deletion_protection
  performance_insights_enabled = var.performance_insights_enabled
  tags                         = local.tags
}

module "alb" {
  source = "../../modules/alb"

  name                       = "${var.project_name}-${var.environment}"
  vpc_id                     = module.networking.vpc_id
  subnet_ids                 = module.networking.public_subnet_ids
  security_group_id          = module.security_groups.alb_security_group_id
  frontend_port              = var.frontend_container_port
  backend_port               = var.backend_container_port
  certificate_arn            = var.certificate_arn
  internal                   = false
  deletion_protection        = var.deletion_protection
  frontend_health_check_path = "/"
  backend_health_check_path  = "/"
  tags                       = local.tags
}

module "ecs_cluster" {
  source = "../../modules/ecs-cluster"

  name                      = "${var.project_name}-${var.environment}"
  enable_container_insights = true
  tags                      = local.tags
}

module "db_migrations" {
  source = "../../modules/db-migrations"

  depends_on = [module.iam]

  name                   = "${var.project_name}-${var.environment}"
  aws_region             = var.aws_region
  cluster_name           = module.ecs_cluster.cluster_name
  subnet_ids             = module.networking.private_app_subnet_ids
  security_group_id      = module.security_groups.backend_security_group_id
  image                  = var.backend_container_image
  execution_role_arn     = module.iam.ecs_task_execution_role_arn
  task_role_arn          = module.iam.backend_task_role_arn
  db_host                = module.rds.db_instance_address
  db_port                = module.rds.db_instance_port
  db_name                = module.rds.db_name
  db_username            = module.rds.db_username
  db_password_secret_arn = module.rds.db_master_password_secret_arn
  tags                   = local.tags
}

module "frontend_service" {
  source = "../../modules/ecs-service"

  depends_on = [module.iam]

  enabled            = var.enable_frontend_service
  service_name       = "${var.project_name}-${var.environment}-frontend"
  cluster_arn        = module.ecs_cluster.cluster_arn
  cluster_name       = module.ecs_cluster.cluster_name
  aws_region         = var.aws_region
  execution_role_arn = module.iam.ecs_task_execution_role_arn
  task_role_arn      = module.iam.frontend_task_role_arn
  container_image    = var.frontend_container_image
  container_port     = var.frontend_container_port
  subnets            = module.networking.private_app_subnet_ids
  security_groups    = [module.security_groups.frontend_security_group_id]
  desired_count      = var.frontend_desired_count
  task_cpu           = 512
  task_memory        = 1024
  target_group_arn   = var.enable_frontend_service ? module.alb.frontend_target_group_arn : null
  container_environment = {
    PORT     = tostring(var.frontend_container_port)
    NODE_ENV = "production"
  }
  health_check_command      = ["CMD-SHELL", "curl -f http://localhost:${var.frontend_container_port}/ || exit 1"]
  health_check_grace_period = 120
  tags                      = local.tags
}

module "backend_service" {
  source = "../../modules/ecs-service"

  depends_on = [module.iam, module.db_migrations]

  enabled            = var.enable_backend_service
  service_name       = "${var.project_name}-${var.environment}-backend"
  cluster_arn        = module.ecs_cluster.cluster_arn
  cluster_name       = module.ecs_cluster.cluster_name
  aws_region         = var.aws_region
  execution_role_arn = module.iam.ecs_task_execution_role_arn
  task_role_arn      = module.iam.backend_task_role_arn
  container_image    = var.backend_container_image
  container_port     = var.backend_container_port
  subnets            = module.networking.private_app_subnet_ids
  security_groups    = [module.security_groups.backend_security_group_id]
  desired_count      = var.backend_desired_count
  task_cpu           = 512
  task_memory        = 1024
  target_group_arn   = var.enable_backend_service ? module.alb.backend_target_group_arn : null
  container_environment = {
    PORT          = tostring(var.backend_container_port)
    NODE_ENV      = "production"
    POSTGRES_HOST = module.rds.db_instance_address
    POSTGRES_PORT = tostring(module.rds.db_instance_port)
    POSTGRES_USER = module.rds.db_username
    POSTGRES_DB   = module.rds.db_name
  }
  secrets = {
    POSTGRES_PASSWORD = "${module.rds.db_master_password_secret_arn}:password::"
    SECRET            = "${aws_secretsmanager_secret.app.arn}:SECRET::"
    REFRESH_SECRET    = "${aws_secretsmanager_secret.app.arn}:REFRESH_SECRET::"
  }
  health_check_command      = ["CMD-SHELL", "curl -f http://localhost:${var.backend_container_port}/ || exit 1"]
  health_check_grace_period = 120
  tags                      = local.tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  project_name          = var.project_name
  environment           = var.environment
  cluster_name          = module.ecs_cluster.cluster_name
  frontend_service_name = var.enable_frontend_service ? module.frontend_service.service_name : "${var.project_name}-${var.environment}-frontend"
  backend_service_name  = var.enable_backend_service ? module.backend_service.service_name : "${var.project_name}-${var.environment}-backend"
  alb_arn_suffix        = module.alb.alb_arn_suffix
  rds_instance_id       = module.rds.db_instance_id
  tags                  = local.tags
}
