# Root Module Outputs - Expose module outputs

# Network Module Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.network.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.network.private_subnet_ids
}

# Backend Module Outputs
output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.backend.cluster_id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.backend.cluster_arn
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.backend.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.backend.cluster_endpoint
}

output "cluster_version" {
  description = "The Kubernetes server version for the EKS cluster"
  value       = module.backend.cluster_version
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.backend.cluster_oidc_issuer_url
}

output "rancher_load_balancer_hostname" {
  description = "Hostname of the Rancher LoadBalancer"  
  value       = module.backend.rancher_load_balancer_hostname
}

output "rancher_load_balancer_url" {
  description = "Full URL to access Rancher"
  value       = module.backend.rancher_load_balancer_url
}

output "rancher_hostname" {
  description = "Rancher hostname (for reference)"
  value       = "rancher.${module.backend.cluster_name}.local"
}

output "rancher_namespace" {
  description = "Rancher namespace"
  value       = module.backend.rancher_namespace
}

output "node_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = module.backend.node_role_arn
}

# Connection Instructions
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.backend.cluster_name}"
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "cluster_info" {
  description = "Cluster connection information"
  value = {
    cluster_name     = module.backend.cluster_name
    cluster_endpoint = module.backend.cluster_endpoint
    region           = var.region
    rancher_url      = module.backend.rancher_load_balancer_url
  }
}
