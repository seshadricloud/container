# Troubleshooting Guide

## Common Issues and Solutions

## Terraform Issues

### Error: Error acquiring the lock

```bash
# Check DynamoDB table
aws dynamodb list-tables | grep terraform-locks

# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### Error: AWS credentials not found

```bash
# Verify AWS CLI configuration
aws sts get-caller-identity

# Reconfigure credentials
aws configure
```

### Error: Insufficient capacity

```bash
# Change instance type or AZ
vi terraform/eks.tf

# Request quota increase
aws service-quotas request-service-quota-increase \
    --service-code ec2 \
    --quota-code L-1216C47A
```

## Kubernetes Issues

### Nodes not joining cluster

```bash
# Describe node status
kubectl describe node <node-name>

# Check node logs
aws ssm start-session --target <instance-id>
sudo journalctl -u kubelet -f
```

### Pods stuck in pending

```bash
# Describe pod for events
kubectl describe pod <pod-name> -n <namespace>

# Check node resources
kubectl top nodes
kubectl top pods

# Check resource requests
kubectl get pod <pod-name> -o yaml | grep -A 5 resources
```

### ImagePullBackOff error

```bash
# Check ECR credentials
kubectl get secret ecr-secret -o yaml

# Update ECR secret
kubectl create secret docker-registry ecr-secret \
    --docker-server=<ECR_REGISTRY> \
    --docker-username=AWS \
    --docker-password=$(aws ecr get-login-password --region us-east-1) \
    --dry-run=client -o yaml | kubectl apply -f -
```

### Service not accessible

```bash
# Check service endpoints
kubectl get endpoints <service-name> -n <namespace>

# Check network policies
kubectl get networkpolicies -n <namespace>

# Test connectivity
kubectl run -it --rm debug --image=alpine -- sh
# Inside: nc -zv <service-name> <port>
```

## Database Issues

### Cannot connect to RDS

```bash
# Check RDS instance status
aws rds describe-db-instances --db-instance-identifier <instance-id>

# Check security group
aws ec2 describe-security-groups --group-ids <sg-id>

# Test connectivity
psql -h <RDS_ENDPOINT> -U postgres -d postgres
```

### Database performance issues

```bash
# Check connections
psql -h <RDS_ENDPOINT> -U postgres -d postgres -c \
    "SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;"

# Check slow queries
psql -h <RDS_ENDPOINT> -U postgres -d myapp -c \
    "SELECT query, calls, mean_time FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"
```

## Network Issues

### ALB target unhealthy

```bash
# Check target group health
aws elbv2 describe-target-health --target-group-arn <tg-arn>

# Verify application health endpoint
curl -v http://<pod-ip>:8080/health
```

### DNS not resolving

```bash
# Check Route53 records
aws route53 list-resource-record-sets --hosted-zone-id <zone-id>

# Test DNS
nslookup api.example.com
dig api.example.com
```

## Application Issues

### High CPU/Memory usage

```bash
# Check resource usage
kubectl top pods -n production

# Scale deployment
kubectl scale deployment application-api --replicas=5
```

### Application errors in logs

```bash
# Check logs
kubectl logs deployment/application-api -n production -f

# Check previous crashes
kubectl logs deployment/application-api -n production --previous
```

---

**Document Version**: 1.0  
**Last Updated**: June 2026