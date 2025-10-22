# module "network" {
#   source = "./modules/network"
#   name   = var.cluster_name
#   cidr   = var.vpc_cidr

#   public_subnets  = var.public_subnets
#   private_subnets = var.private_subnets
#   tags = var.tags
# }

# module "backend" {
#   source = "./modules/backend"

#   cluster_name    = var.cluster_name
#   cluster_version = var.cluster_version
#   vpc_id          = module.network.vpc_id
#   subnet_ids      = concat(module.network.public_subnet_ids, module.network.private_subnet_ids)
#   node_groups     = var.node_groups
#   tags            = var.tags

#   rancher_name       = "rancher"
#   rancher_repository = "https://releases.rancher.com/server-charts/stable"
#   rancher_chart      = "rancher"
#   rancher_version    = var.rancher_version
#   rancher_namespace  = "cattle-system"
#   values_file        = "${path.root}/rancher-values.yaml"
# }

module "kubernetes" {
  source = "./modules/kubernetes"

  cpus                = 2
  memory              = 2048
  kubernetes_version  = "v1.28.3"

  rancher_name        = "rancher"
  rancher_repository  = "https://releases.rancher.com/server-charts/stable"
  rancher_chart       = "rancher"
  rancher_version     = "2.8.5"
  rancher_namespace   = "cattle-system"
  rancher_hostname    = "192.168.49.2.nip.io"
  values_file         = "${path.root}/rancher-values.yaml"
}
