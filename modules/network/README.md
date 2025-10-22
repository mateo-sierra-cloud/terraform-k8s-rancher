Módulo VPC

Propósito
Este módulo crea una VPC básica con subnets públicas y privadas. Está pensado para ser reutilizable desde el entorno.

Inputs principales
- name: prefijo de nombres
- cidr: CIDR principal
- public_subnets: lista de CIDRs públicas
- private_subnets: lista de CIDRs privadas

Outputs
- vpc_id
- public_subnet_ids
- private_subnet_ids

Ejemplo de uso
module "vpc" {
  source         = "../modules/vpc"
  name           = "demo"
  cidr           = "10.0.0.0/16"
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]
}
