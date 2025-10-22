# Configuración para entorno local con Minikube
rancher_version = "2.8.5"

# Variables mantenidas para compatibilidad (no usadas con Minikube)
region = "us-east-1"
cluster_name = "minikube-cluster"
vpc_cidr = "10.0.0.0/16"

public_subnets = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

private_subnets = [
  "10.0.11.0/24",
  "10.0.12.0/24"
]

node_groups = {
  default = {
    desired_size = 2
    min_size     = 1
    max_size     = 3
    instance_types = ["t3.medium"]
  }
}

tags = {
  Environment = "local"
  Owner       = "devops-challenge"
}