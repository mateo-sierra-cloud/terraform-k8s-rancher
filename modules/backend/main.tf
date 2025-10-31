# Backend Module - EKS and Kubernetes Resources
# EKS Cluster, Node Groups, OIDC Provider, Kubernetes Resources

# Data source for AWS caller identity
data "aws_caller_identity" "current" {}

# EKS Cluster IAM Role
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = concat(var.public_subnet_ids, var.private_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  lifecycle {
    ignore_changes = [access_config]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]

  tags = var.tags
}

# OIDC Identity provider (simplified without TLS certificate)
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"] # EKS OIDC root CA thumbprint
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = var.tags
}

# EKS Node Group IAM Role
resource "aws_iam_role" "nodes" {
  name = "${var.cluster_name}-node-group-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}

# EKS Node Groups
resource "aws_eks_node_group" "main" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = each.value.name
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = var.public_subnet_ids  # Changed to public subnets

  capacity_type  = "ON_DEMAND"
  ami_type       = "AL2_x86_64"
  disk_size      = each.value.disk_size
  instance_types = each.value.instance_types

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.nodes_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.nodes_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodes_AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = var.tags
}

# Security Group for additional rules
resource "aws_security_group" "node_group_sg" {
  name_prefix = "${var.cluster_name}-node-group-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all traffic (POC only)"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-node-group-sg"
  })
}

# IAM Role for AWS Load Balancer Controller
resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "${var.cluster_name}-aws-load-balancer-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Condition = {
        StringEquals = {
          "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = var.tags
}

# IAM Policy for AWS Load Balancer Controller
resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "${var.cluster_name}-AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "IAM policy for AWS Load Balancer Controller"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolUsage",
          "ec2:DescribeCoipPools",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule",
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetIpAddressType",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:SetWebAcl",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:RemoveListenerCertificates",
          "elasticloadbalancing:ModifyRule"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:DeleteSecurityGroup"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
  role       = aws_iam_role.aws_load_balancer_controller.name
}

# Access Entry DISABLED - Using only aws-auth ConfigMap to avoid {{SessionName}} placeholder issues
# The pipeline role will be added directly to aws-auth ConfigMap below
locals {
  pipeline_role_arn = trimspace(var.pipeline_deployer_role_arn) != "" ? var.pipeline_deployer_role_arn : null
}

# ConfigMap aws-auth para compatibilidad con roles externos
resource "kubernetes_config_map_v1" "aws_auth" {
  count = var.deploy_k8s ? 1 : 0

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(
      concat([
        {
          rolearn  = aws_iam_role.nodes.arn
          username = "system:node:{{EC2PrivateDNSName}}"
          groups   = ["system:bootstrappers", "system:nodes"]
        }
      ], local.pipeline_role_arn != null ? [
        {
          rolearn  = local.pipeline_role_arn
          username = "github-actions"
          groups   = ["system:masters"]
        }
      ] : [])
    )

    mapUsers = yamlencode([
      { userarn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root", username = "admin", groups = ["system:masters"] },
      { userarn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/lasllaves", username = "lasllaves", groups = ["system:masters"] },
      { userarn = "arn:aws:iam::397952075453:user/jescobar", username = "jescobar", groups = ["system:masters"] }
    ])
  }

  depends_on = [
    aws_eks_node_group.main,
    aws_eks_cluster.main
  ]
}

# Rancher namespace (infrastructure component)
resource "kubernetes_namespace" "cattle_system" {
  count = var.deploy_k8s ? 1 : 0
  metadata { name = "cattle-system" }
  timeouts { delete = "15m" }
  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.main
  ]
}

# ClusterRoleBinding for Rancher ServiceAccount
resource "kubernetes_cluster_role_binding" "rancher_admin" {
  count = var.deploy_k8s ? 1 : 0
  metadata {
    name = "rancher-admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "rancher"
    namespace = "cattle-system"
  }
  depends_on = [kubernetes_namespace.cattle_system]
}

# Ingress for Rancher with ALB
resource "kubernetes_ingress_v1" "rancher_ingress" {
  count = var.deploy_k8s ? 1 : 0
  metadata {
    name      = "rancher-alb"
    namespace = "cattle-system"
    annotations = {
      "kubernetes.io/ingress.class"                  = "alb"
      "alb.ingress.kubernetes.io/scheme"             = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"        = "ip"
      "alb.ingress.kubernetes.io/load-balancer-name" = "rancher-alb"
      "alb.ingress.kubernetes.io/healthcheck-path"   = "/ping"
      "alb.ingress.kubernetes.io/healthcheck-port"   = "80"
      "alb.ingress.kubernetes.io/listen-ports"       = "[{\"HTTP\":80}]"
      "alb.ingress.kubernetes.io/subnets"            = join(",", var.public_subnet_ids)
      "alb.ingress.kubernetes.io/group.name"         = "rancher"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "rancher"
              port { number = 80 }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.aws_load_balancer_controller,
    helm_release.rancher
  ]
}

# AWS Load Balancer Controller installation
resource "helm_release" "aws_load_balancer_controller" {
  count      = var.deploy_k8s ? 1 : 0
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.6.2"

  wait    = true
  timeout = 600

  values = [<<EOF
clusterName: ${aws_eks_cluster.main.name}
serviceAccount:
  create: true
  name: aws-load-balancer-controller
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.aws_load_balancer_controller.arn}
region: us-east-1
vpcId: ${var.vpc_id}
nodeSelector: {}
tolerations: []
affinity: {}
podLabels: {}
podAnnotations: {}
additionalLabels: {}
ingressClass: alb
EOF
  ]

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role.aws_load_balancer_controller,
    aws_iam_role_policy_attachment.aws_load_balancer_controller
  ]
}

# Install Rancher via Helm
resource "helm_release" "rancher" {
  count      = var.deploy_k8s ? 1 : 0
  name       = "rancher"
  repository = "https://releases.rancher.com/server-charts/stable"
  chart      = "rancher"
  namespace  = "cattle-system"
  version    = var.rancher_version

  wait    = false
  timeout = 900

  values = [<<EOF
hostname: rancher.local
tls: external
bootstrapPassword: admin
ingress:
  enabled: false
service:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    name: http
    nodePort: 30080
resources:
  limits:
    cpu: 2000m
    memory: 2Gi
  requests:
    cpu: 500m
    memory: 1Gi
replicas: 1
useBundledSystemChart: true
antiAffinity: preferred
topologySpreadConstraints: []
livenessProbe:
  httpGet:
    path: /healthz
    port: 80
  initialDelaySeconds: 60
  periodSeconds: 30
  timeoutSeconds: 10
  failureThreshold: 6
readinessProbe:
  httpGet:
    path: /healthz
    port: 80
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
EOF
  ]

  depends_on = [
    kubernetes_namespace.cattle_system
  ]
}