# Operational Runbook

## Common Operational Procedures

## Daily Operations

### Morning Checklist

```bash
#!/bin/bash

# Check cluster health
echo "=== Cluster Status ==="
kubectl get nodes
kubectl get pods --all-namespaces | grep -i error

# Check resource usage
echo "=== Resource Usage ==="
kubectl top nodes
kubectl top pods -n production | head -20

# Check RDS
echo "=== Database Status ==="
aws rds describe-db-instances --query 'DBInstances[0].{Status:DBInstanceStatus}'

# Check alerts
echo "=== Active Alarms ==="
aws cloudwatch describe-alarms --state-value ALARM --output table

# Check logs
echo "=== Recent Errors ==="
aws logs tail /aws/ecs/application-api --since 1h --filter-pattern ERROR
```

### Backup Verification

```bash
# Verify RDS backups
aws rds describe-db-snapshots \
    --query 'DBSnapshots[0:5].[DBSnapshotIdentifier,SnapshotCreateTime,Status]' \
    --output table
```

## Incident Response

### Pod Restart

```bash
# Restart single pod
kubectl delete pod <pod-name> -n production

# Restart deployment (rolling)
kubectl rollout restart deployment/application-api -n production

# Monitor
kubectl get pods -n production -w
```

### Database Issue Recovery

```bash
# Check connections
psql -h <RDS_ENDPOINT> -U postgres -d postgres -c \
    "SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;"

# Kill long-running queries
psql -h <RDS_ENDPOINT> -U postgres -d postgres -c \
    "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'active' AND query_start < now() - INTERVAL '1 hour';"

# Restart RDS
aws rds reboot-db-instance --db-instance-identifier production-db
```

## Scaling Operations

### Manual Scaling

```bash
# Scale EKS nodes
aws eks update-nodegroup-config \
    --cluster-name production-eks \
    --nodegroup-name production-nodes \
    --scaling-config minSize=5,maxSize=50,desiredSize=10

# Scale application
kubectl scale deployment application-api --replicas=10 -n production
```

### Auto Scaling Configuration

```bash
# Create HPA
kubectl autoscale deployment application-api \
    --min=3 --max=50 --cpu-percent=70 -n production

# View status
kubectl get hpa -n production
```

## Maintenance Windows

### Drain Node

```bash
# Prepare node for maintenance
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Perform maintenance
# ...

# Return to service
kubectl uncordon <node-name>
```

### Security Patching

```bash
# Update EKS cluster
aws eks update-cluster-version \
    --name production-eks \
    --kubernetes-version 1.29

# Update node group
aws eks update-nodegroup-version \
    --cluster-name production-eks \
    --nodegroup-name production-nodes \
    --kubernetes-version 1.29
```

## Disaster Recovery

### Database Restore

```bash
# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier production-db-restored \
    --db-snapshot-identifier pre-migration-backup

# Update connection string
kubectl patch configmap app-config -p \
    '{"data":{"DB_HOST":"<new-endpoint>"}}'
```

### Full Cluster Restore

```bash
# Apply infrastructure
cd terraform
terraform apply -var-file="environments/prod.tfvars"

# Apply Kubernetes manifests
kubectl apply -f kubernetes/

# Restore secrets
kubectl create secret generic db-secret --from-literal=password=<secret>
```

---

**Document Version**: 1.0  
**Last Updated**: June 2026