# ============================================================================
# AWS Secrets Manager for Database Credentials
# ============================================================================

resource "aws_secretsmanager_secret" "rds_credentials" {
  name_prefix             = "${var.project_name}-${var.environment}-rds-"
  recovery_window_in_days = 7

  tags = merge(
    local.tags,
    {
      Name = "${var.project_name}-${var.environment}-rds-credentials"
    }
  )
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = var.rds_username
    password = var.rds_password
    engine   = var.rds_engine
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    dbname   = var.rds_db_name
  })
}

resource "aws_secretsmanager_secret_policy" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEKSNodesAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.eks_node.arn
        }
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# AWS Secrets Manager for Docker Registry
# ============================================================================

resource "aws_secretsmanager_secret" "docker_config" {
  name_prefix = "${var.project_name}-${var.environment}-docker-"
  description = "Docker registry credentials"

  tags = merge(
    local.tags,
    {
      Name = "${var.project_name}-${var.environment}-docker-config"
    }
  )
}

resource "aws_secretsmanager_secret_version" "docker_config" {
  secret_id = aws_secretsmanager_secret.docker_config.id
  secret_string = jsonencode({
    auths = {
      "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com" = {
        auth = base64encode("AWS:${data.aws_caller_identity.current.account_id}")
      }
    }
  })
}
