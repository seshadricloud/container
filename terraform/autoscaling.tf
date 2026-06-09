# ============================================================================
# Auto Scaling for EKS Nodes
# ============================================================================

resource "aws_autoscaling_group" "eks" {
  name                = "${aws_eks_node_group.main.node_group_name}-asg"
  vpc_zone_identifier = aws_subnet.private[*].id
  min_size            = var.autoscaling_min_nodes
  max_size            = var.autoscaling_max_nodes
  desired_capacity    = var.eks_node_group_desired_size

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-eks-node"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/${local.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

# ============================================================================
# CloudWatch Alarms for ASG
# ============================================================================

resource "aws_cloudwatch_metric_alarm" "asg_cpu" {
  count               = var.enable_alarms && var.autoscaling_enabled ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-asg-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  alarm_description   = "This alarm monitors ASG CPU utilization"
  alarm_actions       = var.alarm_sns_topic_email != "" ? [aws_sns_topic.alarms[0].arn] : []

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.eks.name
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  count                  = var.autoscaling_enabled ? 1 : 0
  name                   = "${var.project_name}-${var.environment}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.eks.name
}

resource "aws_autoscaling_policy" "scale_down" {
  count                  = var.autoscaling_enabled ? 1 : 0
  name                   = "${var.project_name}-${var.environment}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.eks.name
}
