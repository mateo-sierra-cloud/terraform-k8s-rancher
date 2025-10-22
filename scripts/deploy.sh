#!/bin/bash
set -e

echo "Despliegue automatizado: Terraform + Minikube + Rancher"
echo ""

# Verificar dependencias
echo "Verificando dependencias..."
for cmd in docker minikube kubectl terraform helm; do
    if ! command -v $cmd > /dev/null 2>&1; then
        echo "Error: $cmd no está instalado."
        echo "   Instalar con: brew install $cmd"
        exit 1
    fi
done
echo "Todas las dependencias disponibles"

# Paso 1: Setup de Minikube
echo ""
echo "Paso 1: Configurando Minikube..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "$SCRIPT_DIR/setup-minikube.sh" ]; then
    echo "Error: No se encuentra setup-minikube.sh"
    exit 1
fi

chmod +x "$SCRIPT_DIR/setup-minikube.sh"
"$SCRIPT_DIR/setup-minikube.sh"

# Paso 2: Configurar variables de entorno para Terraform
echo ""
echo "Paso 2: Configurando Terraform para Minikube..."
export KUBECONFIG=~/.kube/config
kubectl config use-context minikube

# Verificar conectividad
echo "Verificando conectividad..."
kubectl get nodes
if ! helm list -A > /dev/null 2>&1; then
    echo "Reconfiguración de Helm..."
    kubectl config use-context minikube
fi

# Paso 3: Desplegar con Terraform
echo ""
echo "Paso 3: Desplegando con Terraform..."
cd "$SCRIPT_DIR/.."
terraform init
terraform plan
terraform apply -auto-approve

# Paso 4: Configurar acceso a Rancher
echo ""
echo "Paso 4: Configurando acceso a Rancher..."
MINIKUBE_IP=$(minikube ip)
echo "   IP de Minikube: $MINIKUBE_IP"

# Verificar despliegue
echo ""
echo "Paso 5: Verificando despliegue..."
kubectl wait --for=condition=available deployment/rancher -n cattle-system --timeout=300s
kubectl get pods -n cattle-system
kubectl get svc -n cattle-system
kubectl get ingress -n cattle-system

echo ""
echo "Despliegue completado exitosamente!"
echo ""
echo "Métodos de acceso a Rancher:"
echo ""
echo "1. Via Ingress (requiere túnel):"
echo "   Terminal 1: minikube tunnel"
echo "   Terminal 2: open http://127.0.0.1"
echo ""
echo "2. Via NodePort directo:"
echo "   $(minikube service rancher -n cattle-system --url)"
echo ""
echo "3. Via Port-Forward:"
echo "   kubectl port-forward -n cattle-system svc/rancher 8080:80"
echo "   open http://localhost:8080"
echo ""
echo "Credenciales:"
echo "   Usuario: admin"
echo "   Contraseña: admin"
echo ""
echo "Comandos útiles:"
echo "   kubectl get pods -A                    # Ver todos los pods"
echo "   kubectl get svc -n cattle-system      # Ver servicios de Rancher"
echo "   minikube dashboard                     # Dashboard de Minikube"
echo "   terraform output                       # Ver outputs de Terraform"
echo ""
echo "Para limpiar el entorno:"
echo "   ./scripts/cleanup.sh"