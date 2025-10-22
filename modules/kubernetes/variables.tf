variable "cpus" {
  description = "Número de CPUs para Minikube"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memoria en MB para Minikube"
  type        = number
  default     = 2048
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes para Minikube"
  type        = string
  default     = "v1.28.3"
}

variable "rancher_name" {
  description = "Nombre del release de Rancher"
  type        = string
  default     = "rancher"
}

variable "rancher_repository" {
  description = "Repositorio del chart de Rancher"
  type        = string
  default     = "https://releases.rancher.com/server-charts/stable"
}

variable "rancher_chart" {
  description = "Nombre del chart de Rancher"
  type        = string
  default     = "rancher"
}

variable "rancher_version" {
  description = "Versión del chart de Rancher"
  type        = string
  default     = "2.8.5"
}

variable "rancher_namespace" {
  description = "Namespace donde se desplegará Rancher"
  type        = string
  default     = "cattle-system"
}

variable "values_file" {
  description = "Ruta al archivo values.yaml para personalizar Rancher"
  type        = string
}

variable "rancher_hostname" {
  description = "Hostname para acceder a Rancher mediante el Ingress"
  type        = string
  default     = "rancher.local"
}