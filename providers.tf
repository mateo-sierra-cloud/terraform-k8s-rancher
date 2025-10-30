terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}

# Fallback: lee el cluster existente por nombre si los outputs del módulo aún no están disponibles
data "aws_eks_cluster" "selected" {
  count = var.deploy_k8s ? 1 : 0
  name  = var.cluster_name
}

# Providers de Kubernetes y Helm usando outputs del módulo backend o, si no están, el data source
locals {
  kube_host = coalesce(
    try(module.backend.cluster_endpoint, null),
    try(data.aws_eks_cluster.selected[0].endpoint, null)
  )
  kube_ca = coalesce(
    try(base64decode(module.backend.cluster_certificate_authority), null),
    try(base64decode(data.aws_eks_cluster.selected[0].certificate_authority[0].data), null)
  )
}

provider "kubernetes" {
  host                   = var.deploy_k8s && length(data.aws_eks_cluster.selected) > 0 ? data.aws_eks_cluster.selected[0].endpoint : ""
  cluster_ca_certificate = var.deploy_k8s && length(data.aws_eks_cluster.selected) > 0 ? base64decode(data.aws_eks_cluster.selected[0].certificate_authority[0].data) : ""
  config_path            = var.kubeconfig_path

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = var.deploy_k8s && length(data.aws_eks_cluster.selected) > 0 ? data.aws_eks_cluster.selected[0].endpoint : ""
    cluster_ca_certificate = var.deploy_k8s && length(data.aws_eks_cluster.selected) > 0 ? base64decode(data.aws_eks_cluster.selected[0].certificate_authority[0].data) : ""
    config_path            = var.kubeconfig_path

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    }
  }
}