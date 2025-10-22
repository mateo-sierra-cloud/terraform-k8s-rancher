output "minikube_status" {
  value = module.kubernetes.minikube_status
}

output "kubeconfig_path" {
  value = module.kubernetes.kubeconfig_path
}

output "rancher_release_name" {
  value = module.kubernetes.rancher_release_name
}

output "rancher_url" {
  value = module.kubernetes.rancher_url
}

output "minikube_ip" {
  value = module.kubernetes.minikube_ip
}

output "rancher_access_info" {
  value = module.kubernetes.rancher_access_info
}
