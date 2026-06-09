# ============================================================================
# RDS PostgreSQL Database
# ============================================================================

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(
    local.tags,
    {
      Name = "${var.project_name}-${var.environment}-db-subnet-group"
    }
  )
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-${var.environment}-db"
  engine         = var.rds_engine
  engine_version = var.rds_engine_version
  instance_class = var.rds_instance_class

  allocated_storage = var.rds_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.rds_db_name
  username = var.rds_username
  password = var.rds_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az               = var.rds_multi_az
  publicly_accessible    = false
  skip_final_snapshot    = var.rds_skip_final_snapshot
  final_snapshot_identifier = "${var.project_name}-${var.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  copy_tags_to_snapshot  = true

  backup_retention_period = var.rds_backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  deletion_protection       = var.rds_deletion_protection
  enable_deletion_protection = var.rds_deletion_protection

  enable_iam_database_authentication = true
  enable_cloudwatch_logs_exports     = ["postgresql"]

  monitoring_interval             = var.rds_enable_enhanced_monitoring ? 60 : 0
  monitoring_role_arn             = var.rds_enable_enhanced_monitoring ? aws_iam_role.rds_monitoring.arn : null
  performance_insights_enabled    = true
  performance_insights_retention_period = var.environment == "prod" ? 31 : 7

  parameter_group_name = aws_db_parameter_group.main.name

  tags = merge(
    local.tags,
    {
      Name = "${var.project_name}-${var.environment}-db"
    }
  )

  depends_on = [
    aws_security_group.rds
  ]
}

# ============================================================================
# RDS Parameter Group
# ============================================================================

resource "aws_db_parameter_group" "main" {
  name   = "${var.project_name}-${var.environment}-pg-params"
  family = "postgres${split(".", var.rds_engine_version)[0]}"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = merge(
    local.tags,
    {
      Name = "${var.project_name}-${var.environment}-pg-params"
    }
  )
}

# ============================================================================
# RDS Read Replica (for production)
# ============================================================================

resource "aws_db_instance" "read_replica" {
  count              = var.environment == "prod" ? 1 : 0
  identifier         = "${var.project_name}-${var.environment}-db-read-replica"
  replicate_source_db = aws_db_instance.main.identifier

  instance_class      = var.rds_instance_class
  publicly_accessible = false

  skip_final_snapshot = true

  tags = merge(
    local.tags,
    {
      Name = "${var.project_name}-${var.environment}-db-read-replica"
    }
  )

  depends_on = [aws_db_instance.main]
}

# ============================================================================
# RDS Event Subscription
# ============================================================================

resource "aws_db_event_subscription" "main" {
  count     = var.enable_alarms ? 1 : 0
  name      = "${var.project_name}-${var.environment}-rds-events"
  sns_topic = aws_sns_topic.alarms[0].arn

  source_type = "db-instance"

  event_categories = [
    "availability",
    "failover",
    "failure",
    "maintenance",
    "recovery"
  ]

  tags = merge(
    local.tags,
    {
      Name = "${var.project_name}-${var.environment}-rds-events"
    }
  )
}
