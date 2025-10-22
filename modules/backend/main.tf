module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  eks_managed_node_groups = var.node_groups

  tags = var.tags
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

resource "helm_release" "rancher" {
  name             = var.rancher_name
  repository       = var.rancher_repository
  chart            = var.rancher_chart
  version          = var.rancher_version
  namespace        = var.rancher_namespace
  create_namespace = true

  values = [file(var.values_file)]
}
