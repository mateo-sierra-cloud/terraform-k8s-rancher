terraform {
  required_version = ">= 1.0"
  required_providers {
    helm = { 
      source = "hashicorp/helm"
      version = "~> 2.0"
    }
    null = { 
      source = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Provider helm que usará el kubeconfig local automáticamente
provider "helm" {}