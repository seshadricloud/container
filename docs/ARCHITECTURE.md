# Architecture Overview

## System Architecture

This document provides a comprehensive overview of the AWS DevOps Infrastructure architecture, including all components, their interactions, and design decisions.

## High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Region                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    VPC (CIDR: 10.0.0.0/16)               │  │
│  │                                                          │  │
│  │  ┌─────────────────────────────────────────────────┐   │  │
│  │  │      Public Subnets (Multi-AZ)                 │   │  │
│  │  │  • ALB (Application Load Balancer)             │   │  │
│  │  │  • NAT Gateway                                 │   │  │
│  │  └─────────────────────────────────────────────────┘   │  │
│  │                          ↓                              │  │
│  │  ┌─────────────────────────────────────────────────┐   │  │
│  │  │    Private Subnets (Multi-AZ)                  │   │  │
│  │  │  • EKS Cluster (Kubernetes Masters)            │   │  │
│  │  │  • ECS Cluster                                 │   │  │
│  │  │  • EC2 Worker Nodes                            │   │  │
│  │  │  • ElastiCache (Redis)                         │   │  │
│  │  └─────────────────────────────────────────────────┘   │  │
│  │                          ↓                              │  │
│  │  ┌─────────────────────────────────────────────────┐   │  │
│  │  │   Private Subnets (Database Tier)              │   │  │
│  │  │  • RDS PostgreSQL (Multi-AZ)                   │   │  │
│  │  │  • RDS Read Replicas                           │   │  │
│  │  │  • Secrets Manager                             │   │  │
│  │  └─────────────────────────────────────────────────┘   │  │
│  │                                                          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              AWS Managed Services                        │  │
│  │  • ECR (Elastic Container Registry)                     │  │
│  │  • CloudWatch (Monitoring & Logging)                    │  │
│  │  • CloudTrail (Audit Logging)                           │  │
│  │  • SNS (Simple Notification Service)                    │  │
│  │  • IAM (Identity & Access Management)                   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              ↓
                ┌──────────────────────────────┐
                │    CI/CD Pipeline (Jenkins)  │
                │  • Build & Test              │
                │  • Container Scanning        │
                │  • Deploy to EKS/ECS         │
                └──────────────────────────────┘
```

## Core Components

### 1. **VPC (Virtual Private Cloud)**

**Purpose**: Isolated network environment for AWS resources

**Configuration**:
- **CIDR Block**: 10.0.0.0/16
- **Availability Zones**: 2-3 (Multi-AZ for HA)
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24 (for ALB & NAT)
- **Private Subnets**: 10.0.10.0/24, 10.0.11.0/24 (for compute)
- **Database Subnets**: 10.0.20.0/24, 10.0.21.0/24 (for RDS)

**Key Features**:
- Flow logs for network monitoring
- VPC endpoints for private AWS service access
- NAT Gateways for egress traffic

### 2. **Security Groups & NACLs**

**ALB Security Group**:
- Inbound: 80 (HTTP), 443 (HTTPS) from 0.0.0.0/0
- Outbound: All traffic to application tier

**Application Security Group**:
- Inbound: 8080 from ALB SG, 22 from bastion
- Outbound: All traffic (external APIs, databases)

**Database Security Group**:
- Inbound: 5432 (PostgreSQL) from application tier only
- Outbound: Restricted

### 3. **EKS (Elastic Kubernetes Service)**

**Purpose**: Production-grade managed Kubernetes cluster

**Configuration**:
- Kubernetes Version: 1.28+
- Control Plane: AWS managed (3 AZs)
- Node Groups: On-Demand, Spot, and GPU options
- Cluster autoscaling enabled
- Horizontal Pod Autoscaling (HPA) configured

### 4. **RDS PostgreSQL**

**Purpose**: Managed relational database

**Configuration**:
- Engine: PostgreSQL 15.x
- Multi-AZ: Enabled
- Backup retention: 7-90 days (environment dependent)
- Read replicas for scaling
- Encryption at rest and in transit

### 5. **ECR (Elastic Container Registry)**

**Purpose**: Private Docker container image registry

**Features**:
- Image scanning for vulnerabilities
- Lifecycle policies
- Cross-region replication
- CloudWatch metrics

### 6. **ALB (Application Load Balancer)**

**Purpose**: Distribute traffic across application instances

**Configuration**:
- Internet-facing, Multi-AZ
- SSL/TLS termination
- Path and host-based routing
- Health checks and connection draining

## Data Flow

### Request Flow
```
User Request → Route53 → ALB → Target Group → EKS Pod → Application → RDS
```

### Deployment Flow
```
Git Push → Jenkins → Build → Test → Scan → Push to ECR → Deploy to EKS
```

## Environment Configurations

### Development
- Minimal resources for cost savings
- Single AZ deployment
- Basic monitoring
- Manual approval not required

### Staging
- Near-production setup
- Multi-AZ for HA testing
- Read replicas
- Full monitoring

### Production
- High availability & redundancy
- Multi-AZ across 3 zones
- Multiple read replicas
- Blue-green deployments
- Manual approval required

## High Availability Strategy

### Database HA
- Multi-AZ RDS with automatic failover
- Read replicas for scaling
- Backup and restore procedures

### Application HA
- Multiple instances across AZs
- Load balancing with health checks
- Auto-scaling for demand spikes
- Rolling updates with zero downtime

## Disaster Recovery

### RTO (Recovery Time Objective): 1 hour
### RPO (Recovery Point Objective): 15 minutes

---

**Document Version**: 1.0  
**Last Updated**: June 2026  
**Status**: Production Ready ✅