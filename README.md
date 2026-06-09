# Corporate-Level AWS DevOps Infrastructure

**A production-grade, fully automated infrastructure for deploying containerized microservices on AWS**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Terraform](https://img.shields.io/badge/Terraform-1.0%2B-623CE4?logo=terraform)](https://www.terraform.io)
[![Jenkins](https://img.shields.io/badge/Jenkins-2.400%2B-D24939?logo=jenkins)](https://www.jenkins.io)
[![AWS](https://img.shields.io/badge/AWS-Multi--Service-FF9900?logo=amazon-aws)](https://aws.amazon.com)

## 🏗️ Architecture Overview

This project implements a complete, enterprise-ready AWS infrastructure with:

- **ECR** (Elastic Container Registry) - Docker image storage and management
- **RDS** (Relational Database Service) - PostgreSQL with Multi-AZ, backups, and replication
- **EKS** (Elastic Kubernetes Service) - Production Kubernetes cluster with auto-scaling
- **ECS** (Elastic Container Service) - Alternative container orchestration platform
- **ALB** (Application Load Balancer) - High availability load balancing
- **VPC** - Multi-AZ, highly available networking
- **IAM** - Fine-grained access control and service accounts
- **CloudWatch** - Comprehensive monitoring and logging
- **Jenkins** - Fully automated CI/CD pipeline

## 📁 Project Structure

```
aws-devops-infrastructure/
├── terraform/               # Infrastructure as Code
│   ├── main.tf             # Provider & backend config
│   ├── variables.tf        # Input variables
│   ├── outputs.tf          # Output values
│   ├── vpc.tf              # VPC & Networking
│   ├── iam.tf              # IAM roles & policies
│   ├── security_groups.tf  # Security groups
│   ├── rds.tf              # PostgreSQL RDS
│   ├── ecr.tf              # Container Registry
│   ├── eks.tf              # Kubernetes cluster
│   ├── ecs.tf              # ECS cluster
│   ├── alb.tf              # Load Balancer
│   ├── autoscaling.tf      # Auto Scaling
│   ├── monitoring.tf       # CloudWatch & Alarms
│   ├── secrets.tf          # Secrets Manager
│   ├── environments/       # Environment configs
│   │   ├── dev.tfvars
│   │   ├── staging.tfvars
│   │   └── prod.tfvars
│   └── modules/            # Reusable modules
│
├── jenkins/                # CI/CD Pipeline
│   ├── Jenkinsfile         # Main pipeline
│   ├── Jenkinsfile.eks     # EKS deployment
│   ├── Jenkinsfile.ecs     # ECS deployment
│   ├── Jenkinsfile.terraform  # Infra pipeline
│   ├── docker-compose.yml  # Jenkins setup
│   └── scripts/
│       ├── build.sh        # Docker build
│       ├── deploy.sh       # Deploy script
│       ├── test.sh         # Test script
│       ├── terraform-plan.sh
│       └── rollback.sh
│
├── application/            # Sample Application
│   ├── Dockerfile          # Multi-stage build
│   ├── src/
│   │   ├── app.py         # Flask app
│   │   ├── config.py      # Configuration
│   │   └── requirements.txt
│   └── tests/
│       └── test_app.py
│
├── kubernetes/             # K8s Manifests
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── hpa.yaml            # Auto-scaling
│   └── monitoring/
│       ├── prometheus.yaml
│       └── grafana.yaml
│
├── monitoring/             # Observability
│   ├── cloudwatch-dashboards/
│   ├── alarms/
│   └── scripts/
│
├── docs/                   # Documentation
│   ├── ARCHITECTURE.md
│   ├── SETUP.md
│   ├── DEPLOYMENT.md
│   ├── TROUBLESHOOTING.md
│   ├── RUNBOOK.md
│   └── SECURITY.md
│
├── scripts/                # Utility Scripts
│   ├── init.sh
│   ├── install-tools.sh
│   ├── setup-jenkins.sh
│   └── cleanup.sh
│
└── .gitignore
```

## 🚀 Quick Start

### Prerequisites

```bash
# Required tools
- Terraform >= 1.0
- AWS CLI >= 2.0
- kubectl >= 1.24
- Docker >= 20.0
- Jenkins >= 2.400
- Git
```

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/seshadricloud/aws-devops-infrastructure.git
   cd aws-devops-infrastructure
   ```

2. **Install required tools**
   ```bash
   bash scripts/install-tools.sh
   ```

3. **Configure AWS credentials**
   ```bash
   aws configure
   ```

4. **Initialize Terraform**
   ```bash
   cd terraform
   terraform init
   ```

5. **Plan infrastructure**
   ```bash
   terraform plan -var-file="environments/dev.tfvars" -out=tfplan
   ```

6. **Apply infrastructure**
   ```bash
   terraform apply tfplan
   ```

## 📋 Environment Configurations

### Development
- Smaller RDS instance (db.t3.micro)
- 2-4 EKS nodes
- Single AZ
- Daily backups

### Staging
- Medium RDS instance (db.t3.small)
- 4-8 EKS nodes
- Multi-AZ
- Daily backups (30-day retention)

### Production
- Large RDS instance (db.r5.xlarge)
- 10-50 EKS nodes with auto-scaling
- Multi-AZ with HA
- Hourly backups (90-day retention)
- Cross-region replication

## 🔄 CI/CD Pipeline Flow

```
Developer Commit
    ↓
Git Webhook → Jenkins
    ↓
Checkout & Test
    ↓
Build Docker Image
    ↓
Scan & Push to ECR
    ↓
Update K8s Manifests
    ↓
Terraform Plan (for infra changes)
    ↓
Approval (for prod)
    ↓
Deploy to EKS/ECS
    ↓
Health Checks & Validation
    ↓
Monitoring & Alerts
```

## 🔒 Security Features

✅ Network isolation (VPC with private subnets)
✅ IAM least privilege access
✅ Secrets Manager for credentials
✅ RDS encryption at rest and in transit
✅ VPC endpoints for private AWS access
✅ Security groups with strict rules
✅ CloudTrail for audit logging
✅ Container image scanning
✅ Pod security policies in K8s
✅ SSL/TLS termination at ALB

## 📊 Monitoring & Logging

- **CloudWatch**: Metrics, logs, dashboards
- **Prometheus & Grafana**: Kubernetes-native monitoring
- **CloudTrail**: API audit logging
- **SNS Alerts**: Critical notifications
- **Custom Dashboards**: Application-specific metrics

## 💰 Cost Optimization

- Spot instances for non-critical workloads (70% savings)
- Reserved instances for baseline capacity
- RDS read replicas for scaling
- ElastiCache for query caching
- Auto-scaling based on metrics
- Data transfer optimization

**Estimated Monthly Costs (Production)**:
- EKS Cluster: ~$150
- EC2 Instances (20 nodes): ~$2000
- RDS PostgreSQL: ~$500-800
- ALB: ~$20
- ECR: ~$50-100
- **Total: ~$3000-4000/month**

## 📚 Documentation

Detailed documentation available in `/docs`:

- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - System design and components
- **[SETUP.md](docs/SETUP.md)** - Complete setup guide
- **[DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Deployment procedures
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Common issues and fixes
- **[RUNBOOK.md](docs/RUNBOOK.md)** - Operational procedures
- **[SECURITY.md](docs/SECURITY.md)** - Security best practices

## 🛠️ Key Features

### Infrastructure as Code
- Complete Terraform automation
- Modular design for reusability
- Environment-specific configurations
- State management with S3 backend
- Locking for concurrent safety

### Continuous Integration/Deployment
- Multi-stage Jenkins pipelines
- Automated testing and scanning
- Blue-green deployments
- Canary deployments
- Automatic rollback on failure

### Container Orchestration
- EKS for production-grade Kubernetes
- ECS Fargate for simplified management
- Horizontal Pod Autoscaling (HPA)
- Cluster Autoscaling
- Service discovery and load balancing

### Database Management
- Multi-AZ PostgreSQL RDS
- Automated backups and point-in-time recovery
- Read replicas for scaling reads
- Parameter optimization
- Enhanced monitoring

### High Availability
- Multi-AZ deployment
- Auto-scaling for traffic spikes
- Health checks and self-healing
- Load balancing across instances
- Disaster recovery planning

## 🤝 Contributing

Contributions are welcome! Please:

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Submit a pull request

## 📞 Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check the troubleshooting guide
- Review the runbook for common operations

## 📄 License

MIT License - See LICENSE file for details

## 👤 Author

**Seshadri Cloud**

---

**Last Updated**: June 2026
**Status**: Production Ready ✅
