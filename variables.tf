# AWS Configuration
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "rancher-eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

# EKS Node Groups
variable "node_groups" {
  description = "EKS managed node groups configuration"
  type = map(object({
    name           = string
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    disk_size      = number
  }))
  default = {
    main = {
      name           = "main-nodes"
      instance_types = ["m7i-flex.large"]
      desired_size   = 2
      min_size       = 1
      max_size       = 4
      disk_size      = 50
    }
  }
}

# Application Configuration
variable "rancher_version" {
  description = "Rancher version to deploy"
  type        = string
  default     = "2.8.5"
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "terraform-k8s-rancher"
    ManagedBy   = "terraform"
  }
}

variable "eks_access_entries" {
  description = "Lista de accesos IAM al cluster EKS (Access Entries)"
  type = list(object({
    principal_arn           = string
    type                    = optional(string)
    username                = optional(string)
    kubernetes_groups       = optional(list(string))
    access_policy_arn       = optional(string)
    access_policy_name      = optional(string)
    access_scope_type       = optional(string, "cluster")
    access_scope_namespaces = optional(list(string), [])
  }))
  default = [
    {
      principal_arn      = "arn:aws:iam::397952075453:user/jescobar"
      access_policy_name = "AmazonEKSAdminPolicy"
      username           = "jescobar"
      kubernetes_groups  = ["system:masters"]
    }
  ]
}

variable "deploy_k8s" {
  description = "Si true, crea recursos Kubernetes/Helm (aws-auth, namespaces, controllers, ingress)."
  type        = bool
  default     = false
}

variable "kubeconfig_path" {
  description = "Ruta al kubeconfig a usar por los providers Kubernetes/Helm"
  type        = string
  default     = "/tmp/kubeconfig"
}

variable "pipeline_deployer_role_arn" {
  description = "ARN del rol de IAM usado por el pipeline para desplegar (se le dará acceso admin al EKS)"
  type        = string
  default     = "arn:aws:iam::397952075453:role/github-actions-OIDC"
}

variable "create_pipeline_access" {
  description = "Crear Access Entry para el rol del pipeline antes de recursos K8s"
  type        = bool
  default     = false
}
