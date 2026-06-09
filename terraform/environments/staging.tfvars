# ============================================================================
# Staging Environment Terraform Variables
# ============================================================================

environment           = "staging"
project_name          = "myapp"
aws_region            = "us-east-1"

# VPC Configuration
vpc_cidr              = "10.1.0.0/16"
enable_nat_gateway    = true
single_nat_gateway    = false  # NAT gateway per AZ for HA

# RDS Configuration
rds_instance_class    = "db.t3.small"
rds_allocated_storage = 50
rds_multi_az          = true  # High availability
rds_backup_retention_period = 30
rds_skip_final_snapshot = false
rds_enable_deletion_protection = true
rds_enable_enhanced_monitoring = true

# EKS Configuration
eks_cluster_version   = "1.28"
eks_node_group_min_size = 3
eks_node_group_max_size = 8
eks_node_group_desired_size = 4
eks_node_instance_types = ["t3.medium"]
eks_enable_spot_instances = true

# ECR Configuration
ecr_repository_names = ["myapp", "myapp-api", "myapp-worker"]
ecr_image_scan_on_push = true
ecr_lifecycle_policy_days = 30

# ALB Configuration
alb_name = "myapp-alb-staging"
alb_enable_deletion_protection = false

# Auto Scaling
autoscaling_enabled = true
autoscaling_min_nodes = 3
autoscaling_max_nodes = 8

# Monitoring
enable_cloudwatch_monitoring = true
cloudwatch_log_retention_days = 30
enable_alarms = true
alarm_sns_topic_email = "ops-team@example.com"
cpu_alarm_threshold = 75
memory_alarm_threshold = 80
