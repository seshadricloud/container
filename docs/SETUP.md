# Setup Guide

## Complete Step-by-Step Installation and Configuration

This guide walks you through setting up the entire AWS DevOps Infrastructure from scratch.

## Prerequisites

### Required Software
```bash
terraform --version      # >= 1.0.0
aws --version           # >= 2.13.0
kubectl version         # >= 1.24
docker --version        # >= 20.0
git --version          # >= 2.30
```

### System Requirements
- **OS**: Linux, macOS, or Windows (WSL2)
- **CPU**: 4+ cores
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 50GB free disk space
- **Internet**: High-speed connection

## AWS Account Setup

### Step 1: Create IAM User
```bash
aws iam create-user --user-name terraform-admin
aws iam create-access-key --user-name terraform-admin
aws iam attach-user-policy --user-name terraform-admin \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

### Step 2: Configure AWS Credentials
```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Region, Output format
```

### Step 3: Create S3 Bucket for Terraform State
```bash
aws s3api create-bucket \
  --bucket container-terraform-state-$(date +%s) \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket container-terraform-state-<timestamp> \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket container-terraform-state-<timestamp> \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'
```

## Local Environment Setup

### Step 1: Clone Repository
```bash
git clone https://github.com/seshadricloud/container.git
cd container
```

### Step 2: Install Required Tools

**Terraform**:
```bash
# macOS
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Linux
curl https://releases.hashicorp.com/terraform/1.0.0/terraform_1.0.0_linux_amd64.zip -o terraform.zip
unzip terraform.zip && sudo mv terraform /usr/local/bin/
```

**AWS CLI**:
```bash
# macOS
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install
```

**kubectl**:
```bash
# macOS
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/
```

### Step 3: Verify Installation
```bash
terraform --version
aws --version
kubectl version --client
docker --version
```

## Infrastructure Deployment

### Step 1: Update Terraform Variables
```bash
cd terraform

# Edit environments/dev.tfvars
cat > environments/dev.tfvars << EOF
region              = "us-east-1"
environment         = "dev"
project_name        = "container"
vpc_cidr            = "10.0.0.0/16"
eks_version         = "1.28"
eks_instance_type   = "t3.medium"
eks_desired_size    = 2
rds_instance_class  = "db.t3.micro"
EOF
```

### Step 2: Initialize Terraform
```bash
terraform init

# Should output:
# Terraform has been successfully configured!
```

### Step 3: Validate Configuration
```bash
terraform validate
# Should output: Success! The configuration is valid.
```

### Step 4: Plan Infrastructure
```bash
terraform plan -var-file="environments/dev.tfvars" -out=tfplan
```

### Step 5: Apply Infrastructure
```bash
terraform apply tfplan

# This takes 15-30 minutes
# Save outputs:
terraform output > ../infrastructure-outputs.txt
```

### Step 6: Verify Infrastructure
```bash
# Update kubeconfig
aws eks update-kubeconfig \
  --region us-east-1 \
  --name container-eks-dev

# Test Kubernetes connection
kubectl get nodes
```

## Jenkins Configuration

### Step 1: Deploy Jenkins
```bash
cd ../jenkins
docker-compose up -d

# Wait for startup
sleep 30
```

### Step 2: Initial Setup
```bash
# Get initial admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# Access: http://localhost:8080
# Install suggested plugins
```

### Step 3: Configure Credentials
```bash
# Add AWS credentials
# Manage Jenkins → Manage Credentials → Add Credentials
# Kind: AWS Credentials

# Add GitHub credentials
# Kind: GitHub Personal Access Token
```

## Kubernetes Setup

### Step 1: Create Namespaces
```bash
kubectl create namespace production
kubectl create namespace staging
kubectl create namespace development
kubectl create namespace monitoring
```

### Step 2: Configure Secrets
```bash
kubectl create secret generic db-credentials \
  --from-literal=username=postgres \
  --from-literal=password=<RDS_PASSWORD> \
  -n production
```

### Step 3: Deploy Application Manifests
```bash
cd ../kubernetes

kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
```

## Application Deployment

### Step 1: Build Application
```bash
cd ../application
docker build -t container-app:latest .
```

### Step 2: Push to ECR
```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <ECR_REGISTRY>

docker tag container-app:latest <ECR_REGISTRY>/application-api:latest
docker push <ECR_REGISTRY>/application-api:latest
```

### Step 3: Deploy Application
```bash
kubectl apply -f kubernetes/deployment.yaml -n production
kubectl rollout status deployment/application-api -n production
```

## Verification

```bash
# Check nodes
kubectl get nodes

# Check pods
kubectl get pods --all-namespaces

# Check services
kubectl get svc --all-namespaces

# Test application
ALB_DNS=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[0].DNSName' --output text)
curl http://$ALB_DNS
```

---

**Document Version**: 1.0  
**Last Updated**: June 2026  
**Setup Time**: ~45-60 minutes