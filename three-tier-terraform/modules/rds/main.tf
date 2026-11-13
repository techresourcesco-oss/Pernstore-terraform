resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name}-db-subnet-group"
  })
}

resource "aws_db_instance" "this" {
  identifier                      = "${var.name}-postgres"
  db_name                         = var.db_name
  username                        = var.db_username
  manage_master_user_password     = true
  allocated_storage               = var.allocated_storage
  max_allocated_storage           = var.max_allocated_storage
  storage_type                    = "gp3"
  storage_encrypted               = true
  engine                          = "postgres"
  engine_version                  = var.engine_version
  instance_class                  = var.instance_class
  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = var.vpc_security_group_ids
  multi_az                        = var.multi_az
  backup_retention_period         = var.backup_retention_period
  publicly_accessible             = false
  deletion_protection             = var.deletion_protection
  skip_final_snapshot             = !var.deletion_protection
  performance_insights_enabled    = var.performance_insights_enabled
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  auto_minor_version_upgrade      = true

  tags = merge(var.tags, {
    Name = "${var.name}-rds"
  })
}
