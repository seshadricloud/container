# Frequently Asked Questions

## General Questions

### Q: What is this infrastructure?
**A**: A production-grade AWS infrastructure for deploying containerized microservices using Kubernetes (EKS) or ECS, with automated CI/CD via Jenkins, managed PostgreSQL database, monitoring, and auto-scaling.

### Q: What's the cost?
**A**: Approximately $3,000-4,000/month for production setup including EKS, 20 EC2 nodes, RDS PostgreSQL, ALB, ECR, and CloudWatch.

### Q: Can I use this in production?
**A**: Yes, this is designed for production use with high availability, disaster recovery, security best practices, and comprehensive monitoring.

## Setup Questions

### Q: How long does initial setup take?
**A**: Approximately 45-60 minutes including tool installation, AWS configuration, Terraform apply, and Kubernetes setup.

### Q: Do I need AWS experience?
**A**: Basic AWS knowledge is helpful. This guide includes step-by-step instructions for most operations.

### Q: Can I use different regions?
**A**: Yes, modify `environments/*.tfvars` to change region and availability zones.

### Q: What if I already have AWS resources?
**A**: Use a separate VPC or AWS account to avoid conflicts.

## Deployment Questions

### Q: How do I deploy updates?
**A**: Use Jenkins pipeline for automated deployment, or manually with `kubectl set image` or `aws ecs update-service`.

### Q: What's the best deployment strategy?
**A**: Rolling deployment (default) for normal updates. Blue-green for critical releases. Canary for high-risk changes.

### Q: How do I rollback?
**A**: For Kubernetes: `kubectl rollout undo deployment/app`. For ECS: Redeploy previous task definition.

### Q: How long does deployment take?
**A**: Typically 2-5 minutes for Kubernetes rolling deployment, 1-3 minutes for ECS.

## Database Questions

### Q: How do I backup the database?
**A**: RDS backups are automated. Manual: `aws rds create-db-snapshot --db-instance-identifier production-db`

### Q: How do I scale the database?
**A**: Modify instance class: `aws rds modify-db-instance --db-instance-class db.r5.xlarge --apply-immediately`

### Q: What's the RTO/RPO?
**A**: RTO: 1 hour (restore from backup). RPO: 15 minutes (from latest backup).

## Troubleshooting Questions

### Q: Pod is stuck in pending
**A**: Check node capacity: `kubectl top nodes`. Check resource requests: `kubectl describe pod`. Scale cluster if needed.

### Q: Application is slow
**A**: Check CloudWatch metrics, database connections, and query performance. Scale application or database.

### Q: Cannot access application
**A**: Check ALB target health, security groups, and application logs.

### Q: Terraform state is locked
**A**: Use `terraform force-unlock <LOCK_ID>` carefully. Check DynamoDB lock table.

## Security Questions

### Q: Is data encrypted?
**A**: Yes. RDS encryption enabled, S3 SSE enabled, TLS at ALB, secrets encrypted in Secrets Manager.

### Q: How do I manage secrets?
**A**: Use AWS Secrets Manager. Reference in Kubernetes via secretKeyRef.

### Q: How is audit logging configured?
**A**: CloudTrail logs all API calls. VPC Flow Logs capture network traffic. Application logs in CloudWatch.

## Monitoring Questions

### Q: How do I set up alerts?
**A**: Configure CloudWatch alarms with SNS notifications. Add Prometheus/Grafana for detailed metrics.

### Q: How do I access logs?
**A**: CloudWatch Logs for all services. Stream: `aws logs tail /aws/ecs/application-api --follow`

### Q: What metrics should I monitor?
**A**: CPU/Memory usage, request latency, error rates, database connections, disk space, network throughput.

## Scaling Questions

### Q: How do I auto-scale?
**A**: Create HPA: `kubectl autoscale deployment app --min=3 --max=50 --cpu-percent=70`

### Q: What's the maximum scale?
**A**: Limited by AWS quotas (typically 20 EKS nodes default, request increase for more).

### Q: How much does scaling cost?
**A**: Each additional node: ~$100/month. Monitor and set appropriate max limits.

---

**Document Version**: 1.0  
**Last Updated**: June 2026