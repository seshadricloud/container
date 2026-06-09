# Deployment Guide

## Complete Deployment Procedures and Strategies

This document covers all deployment scenarios, strategies, and operational procedures.

## Deployment Strategies

### 1. Rolling Deployment (Default)

**Best For**: Normal application updates with zero downtime

**Process**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: application-api
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1           # Add 1 extra pod
      maxUnavailable: 0     # Keep 0 pods unavailable
```

### 2. Blue-Green Deployment

**Best For**: Critical production releases requiring instant rollback

```bash
# Deploy green environment
kubectl apply -f deployment-green.yaml -n production

# Route traffic to green
kubectl patch service application-api -p '{"spec":{"selector":{"version":"green"}}}'

# Rollback if needed (instant)
kubectl patch service application-api -p '{"spec":{"selector":{"version":"blue"}}}'
```

### 3. Canary Deployment

**Best For**: High-risk changes with gradual rollout

```bash
# Deploy canary with 10% traffic
kubectl apply -f deployment-canary.yaml

# Monitor metrics
kubectl logs -f deployment/application-api-canary

# Gradually increase traffic to 100%
```

## Pre-Deployment Checklist

- [ ] Code reviewed and approved
- [ ] All tests passed (unit, integration)
- [ ] Container image built and scanned
- [ ] No hardcoded secrets
- [ ] Target environment healthy
- [ ] Backups created
- [ ] Monitoring configured
- [ ] Team notified
- [ ] Rollback procedure tested

## Kubernetes Deployment

### Standard kubectl Deployment

```bash
# Build and push image
docker build -t app:v2.0.0 .
aws ecr get-login-password | docker login --username AWS --password-stdin <ECR_URL>
docker push <ECR_URL>/application-api:v2.0.0

# Update deployment
kubectl set image deployment/application-api \
  application-api=<ECR_URL>/application-api:v2.0.0 \
  -n production

# Monitor rollout
kubectl rollout status deployment/application-api -n production
```

### Jenkins Pipeline for Kubernetes

```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'docker build -t app:${BUILD_NUMBER} .'
            }
        }
        stage('Push') {
            steps {
                sh 'docker push <ECR_URL>/application-api:${BUILD_NUMBER}'
            }
        }
        stage('Deploy') {
            steps {
                sh '''
                    kubectl set image deployment/application-api \
                      application-api=<ECR_URL>/application-api:${BUILD_NUMBER} \
                      -n production
                    kubectl rollout status deployment/application-api -n production
                '''
            }
        }
    }
}
```

## Rollback Procedures

### Kubernetes Rollback

```bash
# View rollout history
kubectl rollout history deployment/application-api -n production

# Rollback to previous version
kubectl rollout undo deployment/application-api -n production

# Rollback to specific revision
kubectl rollout undo deployment/application-api -n production --to-revision=2

# Verify rollback
kubectl rollout status deployment/application-api -n production
```

### Database Rollback

```bash
# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier production-db-restore \
    --db-snapshot-identifier pre-migration-backup

# Update application connection
kubectl patch configmap app-config -p \
    '{"data":{"DB_HOST":"<new-rds-endpoint>"}}'
```

## Post-Deployment Verification

### Application Health Checks

```bash
# Check endpoints
curl -v http://<ALB_DNS>/health
curl -v http://<ALB_DNS>/metrics

# Check logs
kubectl logs -f deployment/application-api -n production

# Check resource usage
kubectl top pods -n production
kubectl top nodes
```

### Performance Validation

```bash
# Load testing
wrk -t4 -c100 -d30s http://<ALB_DNS>/

# Check response times
aws cloudwatch get-metric-statistics \
    --namespace AWS/ApplicationELB \
    --metric-name TargetResponseTime \
    --statistics Average,Maximum
```

### Database Validation

```bash
# Check connections
psql -h <RDS_ENDPOINT> -U postgres -d postgres -c \
    "SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;"

# Check query performance
psql -h <RDS_ENDPOINT> -U postgres -d myapp -c \
    "SELECT query, calls, mean_time FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"
```

---

**Document Version**: 1.0  
**Last Updated**: June 2026