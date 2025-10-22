variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "node_groups" {
  type = any
}

variable "tags" {
  type = map(string)
  default = {}
}

variable "rancher_name" {
  type = string
}

variable "rancher_repository" {
  type = string
}

variable "rancher_chart" {
  type = string
}

variable "rancher_version" {
  type = string
}

variable "rancher_namespace" {
  type = string
}

variable "values_file" {
  type = string
}
