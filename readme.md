# Terraform Kubernetes Rancher

## 📋 Descripción

Este proyecto permite desplegar un cluster Kubernetes con Rancher usando dos enfoques:
1. **Local con Minikube** (configuración actual a**Variables principales**:
- `cpus`: CPUs asignadas a Minikube (default: 2)
- `memory`: Memoria en MB (default: 2048)
- `kubernetes_version`: Versión de K8s (default: v1.28.3)
- `rancher_version`: Versión de Rancher (default: 2.8.5)

### Módulos AWS (Comentados - Para uso futuro)

Los siguientes módulos están disponibles pero comentados para uso con AWS EKS:
- **`network`**: Gestión de VPC, subnets públicas y privadas
- **`backend`**: Orquestación de EKS y Rancher en AWS

Para habilitar AWS EKS en el futuro, simplemente descomenta los módulos en `main.tf` y configura las credenciales de AWS.deal para pruebas sin necesidad de cuenta AWS
2. **AWS EKS** (configuración comentada) - Para entornos de producción

**Nota**: Como no se disponía de una cuenta AWS activa, se optó por implementar la solución completa usando Minikube local. El código para AWS EKS está disponible pero comentado para referencia futura.

Actualmente está configurado para funcionar localmente con Minikube y Docker, proporcionando un entorno completo de desarrollo y pruebas sin costos adicionales.

## 🏗️ Arquitectura del Proyecto

```
terraform-k8s-rancher/
├── main.tf                    # Orquestación principal (usa módulo kubernetes)
├── variables.tf               # Variables globales
├── outputs.tf                # Outputs del cluster
├── providers.tf              # Configuración de providers
├── backend.tf                # Backend local de Terraform
├── terraform.tfvars          # Valores de configuración
├── rancher-values.yaml       # Configuración de Rancher
├── scripts/                  # Scripts de gestión
│   ├── manage.sh             # Script centralizado de gestión
│   ├── setup-minikube.sh     # Setup completo de Minikube
│   ├── deploy.sh             # Despliegue automatizado
│   └── cleanup.sh            # Limpieza completa
├── backend-configs/          # Configuraciones de backend por entorno
├── modules/
│   ├── kubernetes/           # Módulo principal (Minikube + Rancher)
│   ├── network/             # Módulo VPC (comentado)
│   └── backend/             # Módulo EKS + Rancher (comentado)
└── .github/workflows/       # CI/CD workflows
```

## 🛠️ Tecnologías Utilizadas

- **Terraform**: Infraestructura como código
- **Minikube**: Cluster Kubernetes local
- **Docker**: Runtime de contenedores
- **Helm**: Gestor de paquetes de Kubernetes
- **Rancher**: Plataforma de gestión de Kubernetes
- **Nginx Ingress**: Controlador de ingress para exponer servicios

## ⚡ Inicio Rápido

### Requisitos Previos

- Docker Desktop instalado y ejecutándose
- Minikube instalado
- kubectl instalado
- Terraform >= 1.0 instalado
- Helm instalado (opcional para debugging)

### Instalación en macOS

```bash
# Instalar dependencias con Homebrew
brew install terraform minikube kubectl helm docker

# Iniciar Docker Desktop
open -a Docker
```

### Matriz de compatibilidad utilizada:
- **Kubernetes v1.28.3** + **Rancher 2.8.5** = ✅ Compatible
- **Minikube v1.37.0** + **Docker Driver** = ✅ Compatible con macOS ARM64
- Esta combinación es estable y está verificada como disponible en el repositorio oficial

## 🚀 Para usar el proyecto:

**Despliegue rápido:**
```bash
chmod +x scripts/*.sh
./scripts/manage.sh deploy     # Todo en uno
```

**Gestión del entorno:**
```bash
./scripts/manage.sh status     # Ver estado actual
./scripts/manage.sh access     # Como acceder a Rancher
./scripts/manage.sh cleanup    # Limpiar todo
```

## 🤖 GitHub Actions

El proyecto incluye CI/CD automatizado con GitHub Actions:

### Workflows incluidos

1. **🔍 Validación** (en cada PR):
   - Terraform format check
   - Terraform validate
   - Sintaxis de scripts shell
   - Plan de Terraform

2. **🚀 Despliegue** (push a main o manual):
   - Setup completo de Minikube en GitHub
   - Despliegue automatizado de Rancher
   - Verificación de funcionalidad
   - Limpieza opcional

### Configuración del workflow

- **OS**: Ubuntu Latest
- **Minikube**: v1.37.0 con driver Docker  
- **Kubernetes**: v1.28.3
- **Recursos**: 2 CPUs, 2048MB RAM

### Uso de Actions

```bash
# Auto-trigger en push a main
git push origin main

# Manual desde GitHub UI con opciones:
# - Cleanup after deploy: true/false
```

1. **Clonar y navegar al proyecto**:
```bash
git clone <repo-url>
cd terraform-k8s-rancher
```

2. **Configurar y ejecutar Minikube**:
```bash
chmod +x setup-minikube.sh configure-env.sh
./setup-minikube.sh
```

3. **Configurar variables de entorno**:
```bash
source configure-env.sh
```

4. **Desplegar con Terraform**:
```bash
terraform init
terraform plan
terraform apply
```

5. **Configurar acceso a Rancher**:
```bash
# Agregar entrada al archivo hosts
echo "$(minikube ip) rancher.local" | sudo tee -a /etc/hosts

# Obtener la URL de acceso
terraform output rancher_url
```

### Acceso a Rancher

Para acceder a Rancher después del despliegue exitoso, tienes varias opciones:

**Opción 1 - Via Ingress con túnel (recomendado):**
```bash
# En una terminal, mantener ejecutándose:
minikube tunnel

# En otra terminal o navegador:
open http://127.0.0.1
```

**Opción 2 - Via NodePort directo:**
```bash
# Obtener puertos asignados
kubectl get svc rancher -n cattle-system

# Acceder directamente (puertos ejemplo)
open http://192.168.49.2:32083  # HTTP
open https://192.168.49.2:30621 # HTTPS
```

**Opción 3 - Via Port-Forward:**
```bash
kubectl port-forward -n cattle-system svc/rancher 8081:80
open http://localhost:8081
```

**Credenciales:**
- **Usuario**: `admin`
- **Contraseña**: `admin`

### Acceso alternativo con minikube service

```bash
# Abrir automáticamente Rancher usando minikube
minikube service rancher -n cattle-system
```

## 📁 Módulos

### Módulo `kubernetes`

Módulo principal que gestiona:
- Inicialización de cluster Minikube
- Despliegue de Rancher via Helm
- Configuración de Ingress para exposición de servicios
- Habilitación de addons necesarios

**Variables principales**:
- `cpus`: CPUs asignadas a Minikube (default: 2)
- `memory`: Memoria en MB (default: 2048)
- `kubernetes_version`: Versión de K8s (default: v1.26.0)
- `rancher_version`: Versión de Rancher (default: 2.7.9)

### Módulos AWS (Comentados)

- **`network`**: Gestión de VPC, subnets públicas y privadas
- **`backend`**: Orquestación de EKS y Rancher en AWS

## ⚙️ Configuración

### terraform.tfvars

```hcl
# Configuración para entorno local con Minikube
rancher_version = "2.8.5"

# Variables para compatibilidad con AWS (comentadas, no usadas con Minikube)
region = "us-east-1"
cluster_name = "minikube-cluster"
```

### rancher-values.yaml

```yaml
# Configuración para Rancher local
hostname: "rancher.local"
replicas: 1
service:
  type: ClusterIP
ingress:
  enabled: true
  ingressClassName: nginx
bootstrapPassword: "admin"
```

## 🔧 Scripts de Utilidad

Todos los scripts están organizados en la carpeta `scripts/` para mejor organización:

### Scripts principales

1. **`scripts/manage.sh`** - Script centralizado de gestión:
   ```bash
   ./scripts/manage.sh deploy    # Despliegue completo
   ./scripts/manage.sh status    # Ver estado actual
   ./scripts/manage.sh access    # Métodos de acceso a Rancher
   ./scripts/manage.sh cleanup   # Limpiar entorno
   ```

2. **`scripts/setup-minikube.sh`** - Configuración completa de Minikube con cert-manager

3. **`scripts/deploy.sh`** - Despliegue automatizado completo (Minikube + Terraform + Rancher)

4. **`scripts/cleanup.sh`** - Limpieza completa del entorno

### Uso rápido

```bash
# Hacer ejecutables los scripts
chmod +x scripts/*.sh

# Despliegue completo
./scripts/manage.sh deploy

# Ver estado
./scripts/manage.sh status

# Acceder a Rancher
./scripts/manage.sh access
```

## � Comandos Útiles

```bash
# Verificar compatibilidad de versiones
./check-versions.sh

# Actualizar a la última versión disponible de Rancher
./update-rancher-version.sh

# Verificar estado del cluster
kubectl get nodes
kubectl get pods -A

# Ver servicios de Rancher
kubectl get svc -n cattle-system

# Obtener IP de Minikube
minikube ip

# Ver logs de Rancher
kubectl logs -n cattle-system deployment/rancher

# Acceder al dashboard de Minikube
minikube dashboard

# Limpiar y reiniciar
minikube delete
./setup-minikube.sh
```

## 🌐 Configuración para AWS EKS (Disponible pero comentada)

**Nota**: El código está preparado para AWS EKS pero comentado debido a la ausencia de cuenta AWS activa.

Para habilitar la configuración de AWS en el futuro:

1. **Descomentar módulos en main.tf**:
```hcl
module "network" { ... }
module "backend" { ... }
```

2. **Configurar providers.tf para AWS**:
```hcl
provider "aws" {
  region = var.region
}
```

3. **Configurar credenciales AWS**:
```bash
aws configure
# o usar variables de entorno
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
```

4. **Configurar backend remoto S3**:
```bash
# Usar configuración específica por entorno
TF_ENV=dev ./init-terraform.sh
```

### Ventajas del enfoque local vs AWS:

**Minikube Local:**
- ✅ Sin costos de infraestructura
- ✅ Desarrollo y pruebas rápidas
- ✅ No requiere cuenta AWS
- ✅ Ideal para aprendizaje y demos

**AWS EKS (código disponible):**
- ✅ Entorno de producción
- ✅ Alta disponibilidad
- ✅ Escalabilidad automática
- ✅ Integración con servicios AWS

## 🐛 Troubleshooting

### Problemas Comunes

**Error de conexión de Helm/Terraform al cluster**:
```bash
./cleanup.sh          # Limpiar completamente
./setup-minikube.sh    # Reconfigurar Minikube
./terraform-minikube.sh # Configurar Terraform correctamente
```

**Docker no está ejecutándose**:
```bash
open -a Docker
# Esperar a que Docker Desktop esté completamente iniciado
```

**Minikube no inicia**:
```bash
minikube delete
minikube start --driver=docker --cpus=2 --memory=2048
```

**Helm no encuentra el cluster**:
```bash
kubectl config use-context minikube
export KUBE_CONFIG_PATH=~/.kube/config
```

**Rancher no es accesible**:
```bash
**Rancher no es accesible via Ingress**:
```bash
# Verificar que minikube tunnel esté ejecutándose
minikube tunnel

# Verificar ingress controller
kubectl get pods -n ingress-nginx

# Acceder via NodePort como alternativa
minikube service rancher -n cattle-system
```

**Error de conexión rechazada**:
```bash
# Usar port-forward como solución temporal
kubectl port-forward -n cattle-system svc/rancher 8081:80
open http://localhost:8081
```

**Minikube no inicia**:
```

### Logs de Debugging

```bash
# Logs de Terraform
export TF_LOG=DEBUG

# Logs de Minikube
minikube logs

# Logs de Rancher
kubectl logs -n cattle-system -l app=rancher

# Estado del cluster
kubectl describe nodes
```

## 🔒 Consideraciones de Seguridad

- **Contraseñas**: Cambia la contraseña por defecto en producción
- **TLS**: Habilita TLS para conexiones seguras en producción
- **Acceso**: Limita el acceso a la red según tus necesidades
- **Secretos**: No almacenes credenciales en el código

### 🎯 Resultados del proyecto:

- ✅ **Cluster Kubernetes local funcional** con Minikube + Docker
- ✅ **Rancher 2.8.5 desplegado exitosamente** via Helm
- ✅ **Múltiples métodos de acceso** configurados (Ingress, NodePort, Port-Forward)
- ✅ **Infraestructura como código** completamente automatizada con Terraform
- ✅ **Scripts de utilidad** para setup, verificación y troubleshooting
- ✅ **Código AWS EKS listo** para uso futuro cuando se requiera producción
- ✅ **Documentación completa** con ejemplos y troubleshooting

### 🏁 Conclusión

Este proyecto demuestra cómo implementar una solución completa de gestión de contenedores usando:
- **Terraform** para Infrastructure as Code
- **Minikube** para cluster Kubernetes local
- **Rancher** para gestión de clusters
- **Helm** para despliegue de aplicaciones

La implementación local evita costos de nube mientras proporciona un entorno completo para desarrollo, pruebas y aprendizaje. El código para AWS EKS está disponible para migración futura cuando se requiera un entorno de producción.

## 📚 Referencias

- [Terraform Documentation](https://www.terraform.io/docs)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Rancher Documentation](https://rancher.com/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 🤝 Contribución

1. Fork el proyecto
2. Crear feature branch (`git checkout -b feature/nueva-funcionalidad`)
3. Commit cambios (`git commit -am 'Agregar nueva funcionalidad'`)
4. Push branch (`git push origin feature/nueva-funcionalidad`)
5. Crear Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.
