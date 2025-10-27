# This file is no longer used
# Variables have been moved to the root variables.tf file

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_id" {
  description = "ID of the VPC where to create resources"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "node_groups" {
  description = "Map of EKS node group configurations"
  type = map(object({
    name           = string
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    disk_size      = number
  }))
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "rancher_version" {
  description = "Version of Rancher to install"
  type        = string
  default     = "2.8.5"
}

variable "eks_access_entries" {
  description = "Lista de accesos IAM al cluster EKS (Access Entries)"
  type = list(object({
    principal_arn           = string
    type                    = optional(string)            # USER o ROLE
    username                = optional(string)
    kubernetes_groups       = optional(list(string))
    access_policy_arn       = optional(string)            # ARN completo de la policy administrada
    access_policy_name      = optional(string)            # Nombre corto (p. ej. AmazonEKSAdminPolicy) si no se pasa ARN
    access_scope_type       = optional(string, "cluster") # cluster o namespace
    access_scope_namespaces = optional(list(string), [])
  }))
  default = []
}

variable "deploy_k8s" {
  description = "Si true, crea recursos Kubernetes/Helm (aws-auth, namespaces, controllers, ingress)."
  type        = bool
  default     = false
}

variable "pipeline_deployer_role_arn" {
  description = "ARN del rol de IAM usado por el pipeline para desplegar (Access Entry)"
  type        = string
  default     = ""
}

variable "create_pipeline_access" {
  description = "Si true, crea el Access Entry y la asociación de política para el rol del pipeline."
  type        = bool
  default     = false
}
