# Main Terraform configura  tags              = var.tagsn - Root Module
# This file orchestrates all the modules in the correct order

# Network Module - AWS Infrastructure
module "network" {
  source = "./modules/network"

  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  cluster_name    = var.cluster_name
  tags            = var.tags
}

# Backend Module - EKS and Kubernetes
module "backend" {
  source = "./modules/backend"

  cluster_name       = var.cluster_name
  cluster_version    = var.cluster_version
  vpc_id             = module.network.vpc_id
  vpc_cidr_block     = module.network.vpc_cidr_block
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  node_groups        = var.node_groups
  rancher_version    = var.rancher_version
  tags               = var.tags
  eks_access_entries = var.eks_access_entries
  deploy_k8s         = var.deploy_k8s
  pipeline_deployer_role_arn = var.pipeline_deployer_role_arn
  create_pipeline_access     = var.create_pipeline_access

  depends_on = [module.network]
}
