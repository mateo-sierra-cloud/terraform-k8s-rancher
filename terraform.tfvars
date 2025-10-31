# AWS Configuration
region = "us-east-1"

# EKS Cluster Configuration
cluster_name    = "rancher-eks-cluster"
cluster_version = "1.28"

# VPC Configuration
vpc_cidr        = "10.0.0.0/16"
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.10.0/24", "10.0.20.0/24"]

# Node Groups Configuration
node_groups = {
  general = {
    name           = "general"
    instance_types = ["m7i-flex.large"]
    desired_size   = 2
    min_size       = 2
    max_size       = 3
    disk_size      = 20
  }
}

# Rancher Configuration
rancher_version = "2.8.5"

# Tags
tags = {
  Environment = "production"
  Project     = "rancher-k8s"
  ManagedBy   = "terraform"
}