resource "null_resource" "minikube_start" {
  triggers = {
    always_run = timestamp()
  }
  
  provisioner "local-exec" {
    command = <<EOT
      # Verificar que Docker esté ejecutándose
      if ! docker info > /dev/null 2>&1; then
        echo "Error: Docker no está ejecutándose. Por favor inicia Docker Desktop."
        exit 1
      fi
      
      # Detener minikube si está ejecutándose
      minikube stop 2>/dev/null || true
      
      # Eliminar el contexto anterior de kubectl si existe
      kubectl config delete-context minikube 2>/dev/null || true
      kubectl config delete-cluster minikube 2>/dev/null || true
      kubectl config delete-user minikube 2>/dev/null || true
      
      # Iniciar minikube con driver docker
      minikube start --driver=docker --cpus=${var.cpus} --memory=${var.memory} --kubernetes-version=${var.kubernetes_version}
      
      # Configurar kubectl para usar minikube
      kubectl config use-context minikube
      
      # Verificar que kubectl está conectado al contexto correcto
      echo "Contexto actual de kubectl:"
      kubectl config current-context
      
      # Esperar a que el cluster esté listo
      kubectl wait --for=condition=ready nodes --all --timeout=300s
      
      echo "Minikube iniciado correctamente"
    EOT
    
    environment = {
      KUBE_CONFIG_PATH = "~/.kube/config"
      KUBE_CTX = "minikube"
    }
  }
}

# Habilitar ingress addon en minikube
resource "null_resource" "minikube_addons" {
  depends_on = [null_resource.minikube_start]
  
  provisioner "local-exec" {
    command = <<EOT
      minikube addons enable ingress
      minikube addons enable ingress-dns
      
      # Esperar a que el controlador de ingress esté listo
      kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=300s
    EOT
  }
}

# Crear namespace de cert-manager (requerido por Rancher)
resource "null_resource" "cert_manager" {
  depends_on = [null_resource.minikube_addons]
  
  provisioner "local-exec" {
    command = <<EOT
      # Configurar kubectl context
      kubectl config use-context minikube
      
      # Verificar conectividad
      kubectl get nodes
      
      # Agregar repositorio de cert-manager
      helm repo add jetstack https://charts.jetstack.io 2>/dev/null || true
      helm repo update
      
      # Instalar cert-manager usando kubectl context actual
      KUBECONFIG=~/.kube/config helm upgrade --install cert-manager jetstack/cert-manager \
        --namespace cert-manager \
        --create-namespace \
        --set installCRDs=true \
        --wait --timeout=300s \
        --kube-context minikube
    EOT
    
    environment = {
      KUBECONFIG = pathexpand("~/.kube/config")
    }
  }
}

resource "helm_release" "rancher" {
  depends_on = [null_resource.cert_manager]
  
  name             = var.rancher_name
  repository       = var.rancher_repository
  chart            = var.rancher_chart
  version          = var.rancher_version
  namespace        = var.rancher_namespace
  create_namespace = true
  wait             = true
  timeout          = 600
  
  # Forzar recreación si hay problemas
  force_update = true
  cleanup_on_fail = true

  values = [file(var.values_file)]
}

resource "null_resource" "rancher_status" {
  depends_on = [helm_release.rancher]
  
  provisioner "local-exec" {
    command = <<EOT
      # Esperar a que Rancher esté listo
      kubectl wait --for=condition=available deployment/rancher -n cattle-system --timeout=300s
      
      # Verificar que el servicio está funcionando
      kubectl get svc -n cattle-system
      kubectl get ingress -n cattle-system
      
      echo "✅ Rancher desplegado exitosamente"
      echo "📋 Para acceder:"
      echo "   1. Agregar al /etc/hosts: echo \"\$(minikube ip) rancher.local\" | sudo tee -a /etc/hosts"
      echo "   2. Acceder a: http://rancher.local"
    EOT
    
    environment = {
      KUBECONFIG = pathexpand("~/.kube/config")
    }
  }
}

output "kubeconfig_path" {
  description = "Ruta del archivo kubeconfig para el cluster Minikube"
  value       = "~/.kube/config"
}

output "minikube_status" {
  description = "Estado del cluster Minikube"
  value       = "Cluster Minikube inicializado con éxito"
}

output "rancher_release_name" {
  description = "Nombre del release de Rancher"
  value       = helm_release.rancher.name
}

output "rancher_url" {
  description = "URL para acceder a Rancher"
  value       = "http://${var.rancher_hostname} (Agregar primero al /etc/hosts: minikube ip)"
}

output "minikube_ip" {
  description = "Comando para obtener la IP del cluster Minikube"
  value       = "minikube ip"
}

output "rancher_access_info" {
  description = "Información completa para acceder a Rancher"
  value       = "1. minikube ip, 2. sudo echo '<IP> rancher.local' >> /etc/hosts, 3. http://rancher.local"
}
