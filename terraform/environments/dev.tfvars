# ============================================================================
# Development Environment Terraform Variables
# ============================================================================

environment           = "dev"
project_name          = "myapp"
aws_region            = "us-east-1"

# VPC Configuration
vpc_cidr              = "10.0.0.0/16"
enable_nat_gateway    = true
single_nat_gateway    = true  # Cost optimization for dev

# RDS Configuration
rds_instance_class    = "db.t3.micro"
rds_allocated_storage = 20
rds_multi_az          = false  # Not needed for dev
rds_backup_retention_period = 7
rds_skip_final_snapshot = true
rds_enable_deletion_protection = false
rds_enable_enhanced_monitoring = false

# EKS Configuration
eks_cluster_version   = "1.28"
eks_node_group_min_size = 2
eks_node_group_max_size = 4
eks_node_group_desired_size = 2
eks_node_instance_types = ["t3.medium"]
eks_enable_spot_instances = false

# ECR Configuration
ecr_repository_names = ["myapp"]
ecr_image_scan_on_push = true
ecr_lifecycle_policy_days = 7

# ALB Configuration
alb_name = "myapp-alb-dev"
alb_enable_deletion_protection = false

# Auto Scaling
autoscaling_enabled = true
autoscaling_min_nodes = 2
autoscaling_max_nodes = 4

# Monitoring
enable_cloudwatch_monitoring = true
cloudwatch_log_retention_days = 7
enable_alarms = true
alarm_sns_topic_email = ""
cpu_alarm_threshold = 80
memory_alarm_threshold = 85
