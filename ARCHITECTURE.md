# Architecture Diagram - Terraform Kubernetes Rancher Project

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           LOCAL DEVELOPMENT ENVIRONMENT                        │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌──────────────────┐     ┌─────────────────┐     ┌───────────────────────┐    │
│  │   Developer      │────▶│    Terraform    │────▶│     Minikube          │    │
│  │   Machine        │     │                 │     │   (Docker Driver)     │    │
│  │                  │     │  Infrastructure │     │                       │    │
│  │  - Scripts       │     │  as Code        │     │  Kubernetes v1.28.3   │    │
│  │  - Terraform     │     │                 │     │                       │    │
│  │  - kubectl       │     │                 │     │                       │    │
│  │  - Docker        │     │                 │     │                       │    │
│  └──────────────────┘     └─────────────────┘     └───────────────────────┘    │
│                                                             │                   │
│                                                             ▼                   │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │                         KUBERNETES CLUSTER                             │    │
│  │                                                                         │    │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────┐  │    │
│  │  │  cert-manager   │  │ ingress-nginx   │  │      Rancher 2.8.5      │  │    │
│  │  │   namespace     │  │   controller    │  │     cattle-system       │  │    │
│  │  │                 │  │                 │  │       namespace         │  │    │
│  │  │  - SSL Certs    │  │  - LoadBalancer │  │                         │  │    │
│  │  │  - Issuers      │  │  - Routing      │  │  - Web UI              │  │    │
│  │  │                 │  │  - TLS Term     │  │  - API Server           │  │    │
│  │  └─────────────────┘  └─────────────────┘  │  - Cluster Management   │  │    │
│  │                                             │  - User Management      │  │    │
│  │                                             └─────────────────────────┘  │    │
│  └─────────────────────────────────────────────────────────────────────────┘    │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Component Architecture

### 1. Infrastructure Layer
```
Terraform Modules
├── main.tf (Orchestration)
│   ├── kubernetes/ module (Active)
│   ├── network/ module (Commented - AWS)
│   └── backend/ module (Commented - AWS)
│
├── kubernetes/ module
│   ├── Minikube Cluster Management
│   ├── Helm Provider Configuration
│   ├── Rancher Installation
│   ├── Ingress Configuration
│   └── Service Exposure
│
└── AWS Modules (Future Use)
    ├── network/ → VPC, Subnets, IGW
    └── backend/ → EKS, ALB, Route53
```

### 2. Kubernetes Cluster Architecture
```
Minikube Cluster (Single Node)
├── Control Plane
│   ├── API Server
│   ├── etcd
│   ├── Controller Manager
│   └── Scheduler
│
├── Namespaces
│   ├── default
│   ├── kube-system
│   ├── kube-public
│   ├── kube-node-lease
│   ├── cattle-system (Rancher)
│   ├── cert-manager
│   └── ingress-nginx
│
└── Addons
    ├── CoreDNS
    ├── Storage Provisioner
    ├── Metrics Server
    └── Dashboard (Optional)
```

### 3. Rancher Architecture
```
Rancher Management Platform
├── Frontend (React/Vue.js)
│   ├── Dashboard UI
│   ├── Cluster Management
│   ├── Application Catalog
│   └── User Interface
│
├── Backend Services
│   ├── Rancher Server
│   ├── Authentication Service
│   ├── RBAC Management
│   └── Cluster Agent
│
├── Database
│   ├── K3s etcd (Embedded)
│   ├── Cluster State
│   ├── User Data
│   └── Configuration
│
└── Network Services
    ├── Ingress Controller
    ├── Service Mesh (Optional)
    └── Load Balancer
```

## Detailed Data Flow

### 1. Deployment Flow
```
Developer → Scripts → Terraform → Kubernetes → Rancher

1. Developer executes: ./scripts/manage.sh deploy
2. Script validates environment and dependencies
3. Minikube cluster is created/configured
4. Terraform initializes and plans infrastructure
5. Helm deploys cert-manager and ingress-nginx
6. Terraform applies Rancher installation
7. Ingress rules are configured for external access
8. Health checks verify successful deployment
```

### 2. Access Flow
```
User → Ingress → Service → Pod → Application

Browser Request
    ↓
http://127.0.0.1 (via minikube tunnel)
    ↓
Ingress Controller (nginx)
    ↓ (routing rules)
Rancher Service (ClusterIP)
    ↓ (load balancing)
Rancher Pod(s)
    ↓
Rancher Application
```

### 3. Management Flow
```
Rancher UI → Kubernetes API → Cluster Resources

Rancher Dashboard
    ↓ (API calls)
Kubernetes API Server
    ↓ (CRUD operations)
Cluster Resources
    ├── Deployments
    ├── Services
    ├── ConfigMaps
    ├── Secrets
    └── Persistent Volumes
```

## Network Architecture

### Local Network Topology
```
Host Machine Network
├── Docker Bridge Network
│   ├── IP Range: 172.17.0.0/16
│   ├── Docker Containers
│   └── Minikube VM Communication
│
├── Minikube Internal Network
│   ├── Cluster IP Range: 10.96.0.0/12
│   ├── Pod Network: 10.244.0.0/16
│   ├── Service Network: 10.96.0.0/12
│   └── Node IP: 192.168.49.2 (default)
│
└── Host Network Access
    ├── NodePort: 30000-32767
    ├── LoadBalancer: Via minikube tunnel
    └── Port-Forward: kubectl tunneling
```

### Service Exposure Methods
```
External Access Options
├── 1. Ingress + Tunnel (Recommended)
│   ├── minikube tunnel → 127.0.0.1
│   ├── Ingress Controller → nginx
│   └── Service Routing → rancher
│
├── 2. NodePort Direct
│   ├── Minikube IP → 192.168.49.2
│   ├── NodePort → 30000-32767
│   └── Direct Service Access
│
└── 3. Port-Forward
    ├── kubectl port-forward
    ├── Local Port → 8080/8081
    └── Service Tunnel
```

## Security Architecture

### Authentication & Authorization
```
Security Layers
├── Kubernetes RBAC
│   ├── ServiceAccounts
│   ├── Roles & RoleBindings
│   ├── ClusterRoles & ClusterRoleBindings
│   └── Namespace Isolation
│
├── Rancher Authentication
│   ├── Local Users (admin/admin)
│   ├── External Providers (LDAP/AD)
│   ├── SAML/OAuth Integration
│   └── API Token Management
│
└── Network Security
    ├── Ingress TLS Termination
    ├── Service-to-Service Communication
    ├── Network Policies (Optional)
    └── Certificate Management
```

### Certificate Management
```
TLS/SSL Architecture
├── cert-manager
│   ├── Certificate Issuers
│   ├── Certificate Resources
│   ├── Automatic Renewal
│   └── Secret Management
│
├── Ingress TLS
│   ├── TLS Termination
│   ├── Certificate Storage
│   └── SNI Support
│
└── Internal Communication
    ├── Service Mesh TLS
    ├── Pod-to-Pod Encryption
    └── API Server TLS
```

## Deployment Architecture

### Local Development Workflow
```
Development Lifecycle
├── Code Development
│   ├── Terraform Configuration
│   ├── Helm Values
│   ├── Script Automation
│   └── Documentation
│
├── Local Testing
│   ├── Syntax Validation
│   ├── Plan Generation
│   ├── Apply & Verify
│   └── Access Testing
│
└── CI/CD Pipeline
    ├── GitHub Actions
    ├── Automated Testing
    ├── Deployment Validation
    └── Cleanup Procedures
```

### Production Migration Path
```
Migration Strategy (Future AWS)
├── Infrastructure Preparation
│   ├── AWS Account Setup
│   ├── VPC Configuration
│   ├── EKS Cluster Creation
│   └── DNS & Load Balancer
│
├── Application Migration
│   ├── Container Registry
│   ├── Persistent Storage
│   ├── Configuration Management
│   └── Secret Management
│
└── Operational Readiness
    ├── Monitoring Setup
    ├── Backup Strategies
    ├── Disaster Recovery
    └── Performance Tuning
```

## Monitoring & Observability

### Logging Architecture
```
Log Collection & Analysis
├── Kubernetes Logs
│   ├── Pod Logs (kubectl logs)
│   ├── Event Logs (kubectl events)
│   ├── Audit Logs (API Server)
│   └── System Logs (journald)
│
├── Application Logs
│   ├── Rancher Server Logs
│   ├── Ingress Controller Logs
│   ├── cert-manager Logs
│   └── Custom Application Logs
│
└── Infrastructure Logs
    ├── Minikube Logs
    ├── Docker Logs
    ├── Host System Logs
    └── Network Logs
```

### Metrics & Monitoring
```
Monitoring Stack
├── Native Kubernetes Metrics
│   ├── Resource Usage (CPU/Memory)
│   ├── Pod Status & Health
│   ├── Service Endpoints
│   └── Node Conditions
│
├── Rancher Metrics
│   ├── Cluster Health
│   ├── User Activity
│   ├── Application Status
│   └── Performance Metrics
│
└── Infrastructure Metrics
    ├── Minikube Performance
    ├── Docker Statistics
    ├── Host Resource Usage
    └── Network Traffic
```

## Automation & CI/CD

### Script Automation
```
Management Scripts
├── scripts/manage.sh
│   ├── deploy    → Full deployment
│   ├── status    → Health checking
│   ├── access    → Access methods
│   └── cleanup   → Environment cleanup
│
├── scripts/setup-minikube.sh
│   ├── Docker validation
│   ├── Minikube initialization
│   ├── Addon configuration
│   └── Network setup
│
├── scripts/deploy.sh
│   ├── Dependency checking
│   ├── Terraform execution
│   ├── Verification testing
│   └── Access configuration
│
└── scripts/cleanup.sh
    ├── Terraform destroy
    ├── Minikube deletion
    ├── Docker cleanup
    └── State file removal
```

### GitHub Actions Pipeline
```
CI/CD Workflow
├── Validation Phase
│   ├── Terraform Format Check
│   ├── Terraform Validate
│   ├── Shell Script Syntax
│   └── Security Scanning
│
├── Testing Phase
│   ├── Plan Generation
│   ├── Resource Validation
│   ├── Integration Testing
│   └── Performance Testing
│
└── Deployment Phase
    ├── Minikube Setup
    ├── Terraform Apply
    ├── Health Verification
    └── Cleanup (Optional)
```

## Resource Management

### Compute Resources
```
Resource Allocation
├── Minikube Configuration
│   ├── CPUs: 2 cores
│   ├── Memory: 2048 MB
│   ├── Disk: 20 GB (default)
│   └── Driver: Docker
│
├── Rancher Requirements
│   ├── CPU: 500m (request)
│   ├── Memory: 1Gi (request)
│   ├── Replicas: 1 (dev)
│   └── Storage: Persistent volume
│
└── System Overhead
    ├── Kubernetes System Pods
    ├── Ingress Controller
    ├── cert-manager
    └── DNS Resolution
```

### Storage Architecture
```
Storage Management
├── Minikube Storage
│   ├── hostPath provisioner
│   ├── Persistent Volumes
│   ├── Storage Classes
│   └── Volume Claims
│
├── Application Data
│   ├── Rancher Configuration
│   ├── TLS Certificates
│   ├── User Data
│   └── Cluster State
│
└── Backup Strategy
    ├── Configuration Backup
    ├── State Export
    ├── Volume Snapshots
    └── Recovery Procedures
```

## Error Handling & Recovery

### Failure Scenarios
```
Disaster Recovery
├── Minikube Failures
│   ├── Cluster Recreation
│   ├── Node Recovery
│   ├── Network Reset
│   └── Storage Recovery
│
├── Application Failures
│   ├── Pod Restart Policies
│   ├── Service Recovery
│   ├── Configuration Reload
│   └── Health Check Recovery
│
└── Infrastructure Failures
    ├── Docker Service Recovery
    ├── Host System Issues
    ├── Network Connectivity
    └── Resource Exhaustion
```

### Troubleshooting Flow
```
Debug Process
├── Health Assessment
│   ├── Cluster Status Check
│   ├── Pod Status Verification
│   ├── Service Connectivity
│   └── Resource Availability
│
├── Log Analysis
│   ├── Event Examination
│   ├── Error Log Review
│   ├── Performance Metrics
│   └── Network Diagnostics
│
└── Recovery Actions
    ├── Automated Recovery
    ├── Manual Intervention
    ├── Service Restart
    └── Complete Rebuild
```

This architecture provides a comprehensive view of the Terraform Kubernetes Rancher project, highlighting the local development approach while maintaining readiness for future cloud migration.

## AWS Production Architecture (Future Implementation)

### AWS High-Level Architecture
```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                AWS CLOUD                                        │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │                              VPC                                        │    │
│  │                         (10.0.0.0/16)                                  │    │
│  │                                                                         │    │
│  │  ┌──────────────────┐           ┌──────────────────┐                    │    │
│  │  │  Public Subnet   │           │  Private Subnet  │                    │    │
│  │  │  (10.0.1.0/24)   │           │  (10.0.2.0/24)   │                    │    │
│  │  │                  │           │                  │                    │    │
│  │  │  ┌─────────────┐ │           │ ┌──────────────┐ │                    │    │
│  │  │  │     ALB     │ │           │ │ EKS Worker   │ │                    │    │
│  │  │  │ (Rancher)   │◄┼───────────┼─┤   Nodes      │ │                    │    │
│  │  │  └─────────────┘ │           │ │              │ │                    │    │
│  │  │                  │           │ └──────────────┘ │                    │    │
│  │  │  ┌─────────────┐ │           │                  │                    │    │
│  │  │  │     IGW     │ │           │ ┌──────────────┐ │                    │    │
│  │  │  │             │ │           │ │ EKS Control  │ │                    │    │
│  │  │  └─────────────┘ │           │ │   Plane      │ │                    │    │
│  │  └──────────────────┘           │ │  (Managed)   │ │                    │    │
│  │                                 │ └──────────────┘ │                    │    │
│  │                                 └──────────────────┘                    │    │
│  └─────────────────────────────────────────────────────────────────────────┘    │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │                         SUPPORTING SERVICES                            │    │
│  │                                                                         │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                  │    │
│  │  │   Route 53   │  │  Secrets     │  │   ECR        │                  │    │
│  │  │   (DNS)      │  │  Manager     │  │ (Container   │                  │    │
│  │  │              │  │              │  │  Registry)   │                  │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘                  │    │
│  │                                                                         │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                  │    │
│  │  │ CloudWatch   │  │   EBS/EFS    │  │     S3       │                  │    │
│  │  │ (Monitoring) │  │  (Storage)   │  │  (Backups)   │                  │    │
│  │  │              │  │              │  │              │                  │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘                  │    │
│  └─────────────────────────────────────────────────────────────────────────┘    │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### AWS EKS Cluster Architecture
```
Amazon EKS Cluster
├── Control Plane (AWS Managed)
│   ├── API Server (Multi-AZ)
│   ├── etcd (Managed)
│   ├── Controller Manager
│   └── Scheduler
│
├── Data Plane (Customer Managed)
│   ├── Worker Node Groups
│   │   ├── EC2 Instances (t3.medium)
│   │   ├── Auto Scaling Groups
│   │   ├── Launch Templates
│   │   └── Security Groups
│   │
│   └── Fargate Profiles (Optional)
│       ├── Serverless Containers
│       ├── Namespace-based Scheduling
│       └── Pod Execution Role
│
├── Networking
│   ├── VPC CNI Plugin
│   ├── Pod Networking (10.244.0.0/16)
│   ├── Service Discovery
│   └── Network Load Balancers
│
└── Security
    ├── IAM Roles for Service Accounts (IRSA)
    ├── Pod Security Standards
    ├── Secrets Manager Integration
    └── GuardDuty for Kubernetes
```

### AWS Network Architecture
```
Multi-AZ Network Design
├── VPC (10.0.0.0/16)
│   ├── Internet Gateway
│   ├── NAT Gateways (Multi-AZ)
│   └── VPC Endpoints
│
├── Availability Zone A (us-east-1a)
│   ├── Public Subnet (10.0.1.0/24)
│   │   ├── ALB (Application Load Balancer)
│   │   ├── NAT Gateway
│   │   └── Bastion Host (Optional)
│   │
│   └── Private Subnet (10.0.3.0/24)
│       ├── EKS Worker Nodes
│       ├── RDS (if needed)
│       └── EFS Mount Targets
│
├── Availability Zone B (us-east-1b)
│   ├── Public Subnet (10.0.2.0/24)
│   │   ├── ALB (Multi-AZ)
│   │   └── NAT Gateway
│   │
│   └── Private Subnet (10.0.4.0/24)
│       ├── EKS Worker Nodes
│       ├── RDS Standby
│       └── EFS Mount Targets
│
└── Security Groups
    ├── ALB Security Group (80, 443)
    ├── EKS Cluster Security Group
    ├── Worker Node Security Group
    └── Database Security Group (3306)
```

### AWS Rancher Architecture
```
Rancher on AWS EKS
├── Rancher Management Server
│   ├── Deployment (3 replicas for HA)
│   ├── Service (ClusterIP)
│   ├── Ingress (AWS ALB)
│   └── Persistent Storage (EBS/EFS)
│
├── Load Balancing & Ingress
│   ├── AWS Application Load Balancer
│   │   ├── SSL/TLS Termination
│   │   ├── Path-based Routing
│   │   ├── Health Checks
│   │   └── WAF Integration
│   │
│   ├── AWS Load Balancer Controller
│   │   ├── Ingress Management
│   │   ├── Service Load Balancers
│   │   └── Target Group Binding
│   │
│   └── External DNS
│       ├── Route 53 Integration
│       ├── Automatic DNS Management
│       └── Subdomain Automation
│
├── Storage & Persistence
│   ├── EBS CSI Driver
│   │   ├── Dynamic Volume Provisioning
│   │   ├── Volume Snapshots
│   │   └── Encryption at Rest
│   │
│   ├── EFS CSI Driver
│   │   ├── Shared File Systems
│   │   ├── Multi-AZ Access
│   │   └── Backup Integration
│   │
│   └── S3 CSI Driver (Optional)
│       ├── Object Storage
│       ├── Backup Storage
│       └── Log Archival
│
└── Database & State Management
    ├── RDS for MySQL (if external DB)
    │   ├── Multi-AZ Deployment
    │   ├── Automated Backups
    │   ├── Encryption
    │   └── Performance Insights
    │
    └── etcd (EKS Managed)
        ├── Automatic Backups
        ├── Point-in-time Recovery
        └── Encryption at Rest
```

### AWS Security Architecture
```
Comprehensive Security Model
├── Identity & Access Management
│   ├── IAM Roles for Service Accounts (IRSA)
│   │   ├── Pod-level IAM Permissions
│   │   ├── Fine-grained Access Control
│   │   └── Temporary Credentials
│   │
│   ├── EKS Cluster IAM Role
│   │   ├── Cluster Management Permissions
│   │   ├── VPC Access
│   │   └── CloudWatch Logs Access
│   │
│   └── Worker Node IAM Role
│       ├── ECR Access
│       ├── EKS Worker Node Policy
│       └── CNI Policy
│
├── Network Security
│   ├── Security Groups
│   │   ├── Least Privilege Access
│   │   ├── Port-specific Rules
│   │   └── Source-based Restrictions
│   │
│   ├── Network ACLs
│   │   ├── Subnet-level Security
│   │   ├── Stateless Filtering
│   │   └── Defense in Depth
│   │
│   └── VPC Flow Logs
│       ├── Network Traffic Monitoring
│       ├── Security Auditing
│       └── Compliance Logging
│
├── Encryption & Secrets
│   ├── Secrets Manager
│   │   ├── Database Credentials
│   │   ├── API Keys
│   │   ├── Automatic Rotation
│   │   └── Cross-service Integration
│   │
│   ├── AWS KMS
│   │   ├── Envelope Encryption
│   │   ├── Key Rotation
│   │   ├── Audit Logging
│   │   └── Cross-account Access
│   │
│   └── EKS Encryption
│       ├── etcd Encryption at Rest
│       ├── Secrets Encryption
│       └── EBS Volume Encryption
│
└── Compliance & Monitoring
    ├── AWS Config
    │   ├── Resource Compliance
    │   ├── Configuration History
    │   └── Compliance Rules
    │
    ├── GuardDuty
    │   ├── Threat Detection
    │   ├── Malicious Activity Monitoring
    │   └── Kubernetes Audit Log Analysis
    │
    └── Security Hub
        ├── Centralized Security Findings
        ├── Compliance Standards
        └── Multi-account Security
```

### AWS Monitoring & Observability
```
Comprehensive Monitoring Stack
├── Amazon CloudWatch
│   ├── Container Insights
│   │   ├── Cluster-level Metrics
│   │   ├── Node-level Metrics
│   │   ├── Pod-level Metrics
│   │   └── Application Metrics
│   │
│   ├── CloudWatch Logs
│   │   ├── EKS Control Plane Logs
│   │   ├── Application Logs
│   │   ├── VPC Flow Logs
│   │   └── ALB Access Logs
│   │
│   └── CloudWatch Alarms
│       ├── Resource Utilization
│       ├── Error Rate Monitoring
│       ├── Latency Thresholds
│       └── Custom Metrics
│
├── AWS X-Ray
│   ├── Distributed Tracing
│   ├── Service Map
│   ├── Performance Analysis
│   └── Error Root Cause Analysis
│
├── AWS CloudTrail
│   ├── API Call Logging
│   ├── Compliance Auditing
│   ├── Security Event Tracking
│   └── Data Event Logging
│
└── Third-party Integration
    ├── Prometheus & Grafana
    │   ├── Custom Metrics Collection
    │   ├── Advanced Dashboards
    │   ├── AlertManager Integration
    │   └── Long-term Storage
    │
    ├── Fluentd/Fluent Bit
    │   ├── Log Aggregation
    │   ├── Log Parsing
    │   ├── Multi-destination Shipping
    │   └── Buffer Management
    │
    └── Jaeger (Optional)
        ├── Distributed Tracing
        ├── Performance Monitoring
        └── Microservices Observability
```

### AWS Deployment Strategy
```
Production Deployment Pipeline
├── Infrastructure Deployment
│   ├── Terraform Modules
│   │   ├── network/ → VPC, Subnets, Security Groups
│   │   ├── backend/ → EKS, ALB, RDS
│   │   └── monitoring/ → CloudWatch, X-Ray
│   │
│   ├── Multi-Environment Support
│   │   ├── dev.tfvars
│   │   ├── staging.tfvars
│   │   └── prod.tfvars
│   │
│   └── State Management
│       ├── S3 Backend
│       ├── DynamoDB Locking
│       └── State Encryption
│
├── Application Deployment
│   ├── Helm Charts
│   │   ├── Rancher Chart
│   │   ├── Monitoring Stack
│   │   ├── Ingress Controllers
│   │   └── Security Tools
│   │
│   ├── GitOps with ArgoCD
│   │   ├── Declarative Configuration
│   │   ├── Automated Sync
│   │   ├── Rollback Capabilities
│   │   └── Multi-cluster Management
│   │
│   └── CI/CD Pipeline
│       ├── GitHub Actions
│       ├── AWS CodePipeline
│       ├── Container Image Building
│       └── Security Scanning
│
└── Disaster Recovery
    ├── Multi-AZ Deployment
    ├── Cross-region Backups
    ├── RTO/RPO Objectives
    └── Automated Failover
```

### AWS Cost Optimization
```
Cost Management Strategy
├── Resource Optimization
│   ├── Right-sizing Instances
│   │   ├── Instance Type Selection
│   │   ├── Spot Instances for Dev/Test
│   │   ├── Reserved Instances for Prod
│   │   └── Savings Plans
│   │
│   ├── Auto Scaling
│   │   ├── Cluster Autoscaler
│   │   ├── Horizontal Pod Autoscaler
│   │   ├── Vertical Pod Autoscaler
│   │   └── Scheduled Scaling
│   │
│   └── Storage Optimization
│       ├── EBS GP3 vs GP2
│       ├── EFS Intelligent Tiering
│       ├── S3 Lifecycle Policies
│       └── Snapshot Management
│
├── Monitoring & Alerts
│   ├── AWS Cost Explorer
│   ├── AWS Budgets
│   ├── Cost Anomaly Detection
│   └── Resource Tagging Strategy
│
└── Estimated Monthly Costs (Production)
    ├── EKS Control Plane: $73/month
    ├── Worker Nodes (3x t3.medium): ~$65/month
    ├── ALB: ~$22/month
    ├── EBS Storage (100GB): ~$10/month
    ├── NAT Gateway: ~$45/month
    ├── Data Transfer: ~$15/month
    └── Total Estimated: ~$230/month
```

### Migration Strategy (Local to AWS)
```
Phased Migration Approach
├── Phase 1: Infrastructure Setup
│   ├── Uncomment AWS modules in main.tf
│   ├── Configure AWS provider
│   ├── Set up Terraform backend (S3)
│   ├── Deploy network infrastructure
│   └── Deploy EKS cluster
│
├── Phase 2: Application Migration
│   ├── Build container images
│   ├── Push to ECR
│   ├── Migrate Helm values
│   ├── Deploy Rancher to EKS
│   └── Configure ingress and DNS
│
├── Phase 3: Data Migration
│   ├── Export Rancher configuration
│   ├── Backup cluster state
│   ├── Import to new cluster
│   └── Verify functionality
│
└── Phase 4: Production Readiness
    ├── Configure monitoring
    ├── Set up backups
    ├── Security hardening
    ├── Performance tuning
    └── Documentation update
```

This comprehensive AWS architecture provides a production-ready, highly available, and scalable environment for running Rancher on Amazon EKS, while maintaining the same Terraform-based infrastructure as code approach used in the local development setup.