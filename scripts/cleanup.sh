#!/bin/bash

echo "Limpiando entorno para resolver conflictos..."

# Destruir recursos de Terraform si existen
if [ -f "terraform.tfstate" ]; then
    echo "Destruyendo recursos de Terraform..."
    terraform destroy -auto-approve 2>/dev/null || echo "Algunos recursos ya fueron eliminados"
fi

# Limpiar instalaciones de Helm
echo "Eliminando instalaciones de Helm..."
helm uninstall rancher -n cattle-system 2>/dev/null || echo "   Rancher no encontrado"
helm uninstall cert-manager -n cert-manager 2>/dev/null || echo "   cert-manager no encontrado"

# Eliminar namespaces
echo "Eliminando namespaces..."
kubectl delete namespace cattle-system 2>/dev/null || echo "   cattle-system no encontrado"
kubectl delete namespace cert-manager 2>/dev/null || echo "   cert-manager no encontrado"

# Limpiar Minikube completamente
echo "Reiniciando Minikube..."
minikube delete 2>/dev/null || echo "   Minikube no estaba ejecutándose"

# Limpiar archivos de Terraform
echo "Limpiando archivos de Terraform..."
rm -rf .terraform/ .terraform.lock.hcl terraform.tfstate* 2>/dev/null || true

echo ""
echo "Limpieza completada. El entorno está listo para un nuevo despliegue."
echo ""
echo "Para volver a desplegar:"
echo "   1. ./scripts/setup-minikube.sh"
echo "   2. ./scripts/deploy.sh"
echo "   O simplemente: ./scripts/manage.sh deploy"