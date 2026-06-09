# ============================================================================
# Production Environment Terraform Variables
# ============================================================================

environment           = "prod"
project_name          = "myapp"
aws_region            = "us-east-1"

# VPC Configuration
vpc_cidr              = "10.2.0.0/16"
enable_nat_gateway    = true
single_nat_gateway    = false  # Separate NAT gateways per AZ

# RDS Configuration
rds_instance_class    = "db.r5.xlarge"  # Memory-optimized for production
rds_allocated_storage = 200
rds_multi_az          = true  # Critical for production
rds_backup_retention_period = 90  # Extended retention
rds_skip_final_snapshot = false  # Always create final snapshot
rds_enable_deletion_protection = true  # Prevent accidental deletion
rds_enable_enhanced_monitoring = true

# EKS Configuration
eks_cluster_version   = "1.28"
eks_node_group_min_size = 5
eks_node_group_max_size = 50
eks_node_group_desired_size = 10
eks_node_instance_types = ["t3.large"]
eks_enable_spot_instances = true  # Cost optimization with mix of on-demand and spot

# ECR Configuration
ecr_repository_names = ["myapp", "myapp-api", "myapp-worker", "myapp-scheduler"]
ecr_image_scan_on_push = true
ecr_lifecycle_policy_days = 90  # Keep images longer in production

# ALB Configuration
alb_name = "myapp-alb-prod"
alb_enable_deletion_protection = true  # Prevent accidental deletion

# Auto Scaling
autoscaling_enabled = true
autoscaling_min_nodes = 5
autoscaling_max_nodes = 50

# Monitoring
enable_cloudwatch_monitoring = true
cloudwatch_log_retention_days = 90
enable_alarms = true
alarm_sns_topic_email = "ops-team@example.com,alerts@example.com"
cpu_alarm_threshold = 70  # Lower threshold for production
memory_alarm_threshold = 75
