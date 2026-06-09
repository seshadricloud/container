# Security Best Practices

## Comprehensive Security Guide

## Network Security

### VPC Configuration

```bash
# Private subnets for application
aws ec2 create-subnet --vpc-id vpc-xxx --cidr-block 10.0.10.0/24 \
    --availability-zone us-east-1a

# NAT Gateway for egress
aws ec2 allocate-address --domain vpc
aws ec2 create-nat-gateway --subnet-id subnet-xxx --allocation-id eipalloc-xxx

# VPC Endpoints for private AWS access
aws ec2 create-vpc-endpoint --vpc-id vpc-xxx --service-name com.amazonaws.us-east-1.s3 \
    --route-table-ids rtb-xxx
```

### Security Groups

```bash
# ALB Security Group - Allow HTTP/HTTPS
aws ec2 create-security-group --group-name alb-sg --description "ALB" --vpc-id vpc-xxx
aws ec2 authorize-security-group-ingress --group-id sg-xxx \
    --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id sg-xxx \
    --protocol tcp --port 443 --cidr 0.0.0.0/0

# Application Security Group - Allow from ALB only
aws ec2 create-security-group --group-name app-sg --description "App" --vpc-id vpc-xxx
aws ec2 authorize-security-group-ingress --group-id sg-yyy \
    --protocol tcp --port 8080 --source-group sg-xxx

# Database Security Group - Allow from App only
aws ec2 create-security-group --group-name db-sg --description "DB" --vpc-id vpc-xxx
aws ec2 authorize-security-group-ingress --group-id sg-zzz \
    --protocol tcp --port 5432 --source-group sg-yyy
```

## Identity & Access

### IAM Roles

```bash
# EKS Service Role
aws iam create-role --role-name eks-service-role \
    --assume-role-policy-document file://eks-trust-policy.json
aws iam attach-role-policy --role-name eks-service-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKSServiceRolePolicy

# Node IAM Role
aws iam create-role --role-name eks-node-role \
    --assume-role-policy-document file://ec2-trust-policy.json
```

### RBAC in Kubernetes

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: production
rules:
- apiGroups: [""]
  resources: ["pods", "pods/logs"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: production
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: developer
subjects:
- kind: User
  name: developer@example.com
```

## Data Security

### Encryption at Rest

```bash
# RDS Encryption
aws rds create-db-instance \
    --db-instance-identifier production-db \
    --engine postgres \
    --storage-encrypted \
    --kms-key-id arn:aws:kms:us-east-1:123456789012:key/12345678

# S3 Bucket Encryption
aws s3api put-bucket-encryption \
    --bucket mybucket \
    --server-side-encryption-configuration '{
        "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
    }'
```

### Encryption in Transit

```bash
# ALB SSL Certificate
aws acm request-certificate \
    --domain-name example.com \
    --subject-alternative-names api.example.com

# RDS SSL Requirement
aws rds modify-db-instance \
    --db-instance-identifier production-db \
    --require-iam-database-authentication
```

## Container Security

### Image Scanning

```bash
# ECR Image Scanning
aws ecr put-image-scanning-configuration \
    --repository-name application-api \
    --image-scanning-configuration scanOnPush=true

# Trivy scanning
trivy image <ECR_REGISTRY>/application-api:latest
```

### Secrets Management

```bash
# Store secrets in Secrets Manager
aws secretsmanager create-secret \
    --name app/db-password \
    --secret-string '{"username":"postgres","password":"strongpassword"}'

# Use in Kubernetes
kubectl create secret generic db-secret \
    --from-literal=password=$(aws secretsmanager get-secret-value --secret-id app/db-password --query SecretString --output text)
```

## Audit & Compliance

### CloudTrail Configuration

```bash
# Create CloudTrail
aws cloudtrail create-trail \
    --name organization-trail \
    --s3-bucket-name my-cloudtrail-bucket \
    --is-multi-region-trail

# Enable logging
aws cloudtrail start-logging --trail-name organization-trail
```

### CloudWatch Monitoring

```bash
# Alarm for unauthorized API calls
aws cloudwatch put-metric-alarm \
    --alarm-name UnauthorizedAPICallsAlarm \
    --metric-name UnauthorizedOperationCount \
    --namespace CloudTrailMetrics \
    --statistic Sum \
    --threshold 1
```

## Security Checklist

✅ VPC with private subnets  
✅ IAM least privilege access  
✅ Secrets Manager for credentials  
✅ RDS encryption at rest and in transit  
✅ VPC endpoints for private AWS access  
✅ Security groups with strict rules  
✅ CloudTrail for audit logging  
✅ Container image scanning  
✅ Pod security policies in K8s  
✅ SSL/TLS termination at ALB  

---

**Document Version**: 1.0  
**Last Updated**: June 2026