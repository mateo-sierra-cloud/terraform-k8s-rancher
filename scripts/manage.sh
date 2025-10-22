#!/bin/bash

echo "Gestión de entorno Terraform + Minikube + Rancher"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

show_help() {
    echo "Uso: $0 [COMANDO]"
    echo ""
    echo "Comandos disponibles:"
    echo "  setup     - Configurar Minikube y dependencias"
    echo "  deploy    - Despliegue completo (setup + terraform)"
    echo "  cleanup   - Limpiar completamente el entorno"
    echo "  status    - Ver estado actual del entorno"
    echo "  access    - Mostrar métodos de acceso a Rancher"
    echo "  help      - Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 deploy     # Despliegue completo"
    echo "  $0 status     # Ver estado"
    echo "  $0 cleanup    # Limpiar todo"
}

show_status() {
    echo "Estado del entorno:"
    echo ""
    
    if minikube status > /dev/null 2>&1; then
        echo "Minikube: Ejecutándose"
        echo "   IP: $(minikube ip)"
    else
        echo "Minikube: No está ejecutándose"
    fi
    
    if kubectl get nodes > /dev/null 2>&1; then
        echo "Kubectl: Conectado"
        echo "   Contexto: $(kubectl config current-context)"
    else
        echo "Kubectl: No conectado"
    fi
    
    if kubectl get deployment rancher -n cattle-system > /dev/null 2>&1; then
        echo "Rancher: Desplegado"
        kubectl get deployment rancher -n cattle-system
    else
        echo "Rancher: No desplegado"
    fi
}

show_access() {
    echo "Métodos de acceso a Rancher:"
    echo ""
    
    if kubectl get svc rancher -n cattle-system > /dev/null 2>&1; then
        echo "1. Via minikube service:"
        minikube service rancher -n cattle-system --url
        echo ""
        echo "2. Via port-forward:"
        echo "   kubectl port-forward -n cattle-system svc/rancher 8080:80"
        echo "   open http://localhost:8080"
        echo ""
        echo "3. Via ingress + tunnel:"
        echo "   Terminal 1: minikube tunnel"
        echo "   Terminal 2: open http://127.0.0.1"
        echo ""
        echo "Credenciales:"
        echo "   Usuario: admin"
        echo "   Contraseña: admin"
    else
        echo "Rancher no está desplegado"
        echo "   Ejecutar: $0 deploy"
    fi
}

case "$1" in
    setup)
        chmod +x "$SCRIPT_DIR/setup-minikube.sh"
        "$SCRIPT_DIR/setup-minikube.sh"
        ;;
    deploy)
        chmod +x "$SCRIPT_DIR/deploy.sh"
        "$SCRIPT_DIR/deploy.sh"
        ;;
    cleanup)
        chmod +x "$SCRIPT_DIR/cleanup.sh"
        cd "$PROJECT_ROOT"
        "$SCRIPT_DIR/cleanup.sh"
        ;;
    status)
        show_status
        ;;
    access)
        show_access
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Comando no reconocido: $1"
        echo ""
        show_help
        exit 1
        ;;
esac