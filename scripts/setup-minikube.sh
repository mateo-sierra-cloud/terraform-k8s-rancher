#!/bin/bash
set -e

echo "Setup completo de Minikube para Terraform + Rancher"
echo ""

echo "Verificando Docker..."
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker no está ejecutándose."
    echo "Por favor inicia Docker Desktop e intenta de nuevo."
    exit 1
fi
echo "Docker está ejecutándose"

echo "Verificando versiones..."
echo "   Minikube: $(minikube version --short)"
echo "   Docker: $(docker version --format '{{.Server.Version}}')"
echo "   kubectl: $(kubectl version --client --short)"
echo "   Helm: $(helm version --short)"

echo "Deteniendo Minikube si está ejecutándose..."
minikube stop 2>/dev/null || true

echo "Limpiando configuración anterior..."
kubectl config delete-context minikube 2>/dev/null || true
kubectl config delete-cluster minikube 2>/dev/null || true
kubectl config delete-user minikube 2>/dev/null || true

echo "Iniciando Minikube..."
minikube start --driver=docker --cpus=2 --memory=2048 --kubernetes-version=v1.28.3

echo "Configurando kubectl..."
kubectl config use-context minikube

echo "Verificando cluster..."
kubectl config current-context
kubectl wait --for=condition=ready nodes --all --timeout=300s

echo "Habilitando addons..."
minikube addons enable ingress
minikube addons enable ingress-dns

echo "Esperando ingress controller..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

echo "Instalando cert-manager..."
helm repo add jetstack https://charts.jetstack.io 2>/dev/null || true
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true \
  --wait --timeout=300s

echo ""
echo "Minikube está listo!"
echo "Información del cluster:"
echo "   IP: $(minikube ip)"
echo "   Contexto: $(kubectl config current-context)"
echo ""
echo "Siguiente paso: ./scripts/deploy.sh"