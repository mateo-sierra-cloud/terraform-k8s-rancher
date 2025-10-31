# Terraform K8s Rancher Pipeline

Infrastructure as Code pipeline to deploy Kubernetes with Rancher using Terraform on AWS.

## 📋 Prerequisites

1. **GitHub OIDC Configuration**
   - Configure OIDC provider in AWS IAM
   - Create IAM role with trust relationship for GitHub Actions

2. **AWS IAM Role Setup**
   ```bash
   # Create OIDC provider
   aws iam create-open-id-connect-provider \
     --url https://token.actions.githubusercontent.com \
     --client-id-list sts.amazonaws.com

   # Create role with trust policy for your repository
   # Role name: github-actions-terraform-role
   ```

3. **GitHub Secrets**
   - `AWS_ROLE_ARN`: ARN of the IAM role created

## 🚀 Running the Workflow

The pipeline runs automatically on:
- Push to `main` branch
- Pull requests to `main`
- Manual trigger via GitHub Actions UI

### Manual Execution
1. Go to **Actions** tab in GitHub
2. Select the workflow
3. Click **Run workflow**

## 📁 Project Structure

```
.
├── .github/
│   └── workflows/       # GitHub Actions workflows
├── main.tf              # Main Terraform configuration
├── variables.tf         # Input variables
├── outputs.tf          # Outputs
└── providers.tf        # AWS provider configuration
```

## 🔧 IAM Role Permissions Required

- EC2 (full access)
- VPC (full access)
- IAM (create roles for K8s)
- EKS (full access)

---
**Note**: Review costs before deploying to production.
