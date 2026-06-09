# ============================================================================
# CloudWatch Log Group (general)
# ============================================================================

resource "aws_cloudwatch_log_group" "main" {
  name              = "/aws/${var.project_name}/${var.environment}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(
    local.tags,
    {
      Name = "/aws/${var.project_name}/${var.environment}"
    }
  )
}

# ============================================================================
# SNS Topic for Alarms
# ============================================================================

resource "aws_sns_topic" "alarms" {
  count = var.enable_alarms ? 1 : 0
  name  = "${var.project_name}-${var.environment}-alarms"

  tags = merge(
    local.tags,
    {
      Name = "${var.project_name}-${var.environment}-alarms"
    }
  )
}

resource "aws_sns_topic_subscription" "alarms" {
  count     = var.enable_alarms && var.alarm_sns_topic_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = var.alarm_sns_topic_email
}

# ============================================================================
# CloudWatch Alarm - EKS Cluster CPU
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "eks_node_cpu" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-eks-node-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  alarm_description   = "Alert when EKS node CPU exceeds threshold"
  alarm_actions       = [aws_sns_topic.alarms[0].arn]
}

# ============================================================================
# CloudWatch Alarm - RDS CPU
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  alarm_description   = "Alert when RDS CPU exceeds threshold"
  alarm_actions       = [aws_sns_topic.alarms[0].arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
}

# ============================================================================
# CloudWatch Alarm - RDS Database Connections
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "rds_database_connections" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when RDS connections exceed threshold"
  alarm_actions       = [aws_sns_topic.alarms[0].arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
}

# ============================================================================
# CloudWatch Alarm - RDS Disk Space
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "rds_free_disk_space" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-rds-free-disk-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 1073741824 # 1 GB in bytes
  alarm_description   = "Alert when RDS free disk space is low"
  alarm_actions       = [aws_sns_topic.alarms[0].arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
}

# ============================================================================
# CloudWatch Alarm - ALB Unhealthy Hosts
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Alert when ALB has unhealthy hosts"
  alarm_actions       = [aws_sns_topic.alarms[0].arn]

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.main.arn_suffix
  }
}

# ============================================================================
# CloudWatch Dashboard
# ============================================================================

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", { stat = "Average" }],
            ["AWS/RDS", "DatabaseConnections", { stat = "Average" }],
            ["AWS/RDS", "FreeStorageSpace", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { stat = "Average" }],
            ["AWS/ApplicationELB", "RequestCount", { stat = "Sum" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ALB Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average" }],
            ["AWS/EC2", "NetworkIn", { stat = "Sum" }],
            ["AWS/EC2", "NetworkOut", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 Metrics"
        }
      }
    ]
  })
}
