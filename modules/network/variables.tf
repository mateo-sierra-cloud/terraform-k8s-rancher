variable "name" {
  description = "Prefijo de nombres"
  type        = string
}

variable "cidr" {
  description = "CIDR principal"
  type        = string
}

variable "public_subnets" {
  description = "Lista de subnets públicas"
  type        = list(string)
}

variable "private_subnets" {
  description = "Lista de subnets privadas"
  type        = list(string)
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default     = {}
}