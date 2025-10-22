# Variables para configuración local con Minikube
variable "region" {
  description = "AWS region (no usado para Minikube, mantenido para compatibilidad)"
  type        = string
  default     = "us-east-1"
}

# Variables mantenidas para compatibilidad, pero no usadas en configuración local
variable "cluster_name" {
  description = "Nombre del cluster (no usado con Minikube)"
  type        = string
  default     = "minikube-cluster"
}

variable "vpc_cidr" {
  description = "CIDR principal de la VPC (no usado con Minikube)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "CIDRs de subnets públicas (no usado con Minikube)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "CIDRs de subnets privadas (no usado con Minikube)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "node_groups" {
  description = "Definición de node groups (no usado con Minikube)"
  type        = any
  default = {
    example = {
      desired_size = 2
      min_size     = 1
      max_size     = 3
      instance_types = ["t3.medium"]
    }
  }
}

variable "cluster_version" {
  description = "Versión de Kubernetes (no usado con Minikube)"
  type        = string
  default     = "1.27"
}

variable "rancher_version" {
  description = "Versión del chart de Rancher"
  type        = string
  default     = "2.8.5"
}

variable "tags" {
  description = "Tags por defecto para recursos (no usado con Minikube)"
  type        = map(string)
  default     = { Owner = "devops-challenge" }
}
