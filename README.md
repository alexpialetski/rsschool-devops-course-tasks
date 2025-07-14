# RS School DevOps Course Tasks

This repository contains Infrastructure as Code (IaC) solutions for the RS School DevOps Course. The project uses Terraform to provision AWS infrastructure for a Kubernetes cluster using k3s, with an automated CI/CD pipeline built on GitHub Actions and Nx workspace management.

## 🏗️ Architecture Overview

The infrastructure consists of three main components:

1. **Local Package** (`packages/local/`) - Development environment and Github secrets setup scripts
2. **Setup Package** (`packages/setup/`) - Creates the AWS S3 backend for Terraform state management
3. **Cluster Package** (`packages/cluster/`) - Provisions a K3s Kubernetes cluster on AWS

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with appropriate credentials
- Node.js (v20+) and npm
- Terraform (v1.8+)
- GitHub CLI (`gh`) for secrets management

### Dev Environment Setup

#### Option 1: Quick Setup (Recommended for New Accounts)

1. **Create AWS Credentials File**
   Create a `.keys` file in the root directory:
   ```bash
   # .keys file content
   AWS_ACCESS_KEY_ID=your-access-key-id
   AWS_SECRET_ACCESS_KEY=your-secret-access-key
   ```

2. **Run Automated Setup**
   ```bash
   # Install dependencies
   npm install
   
   # Configure AWS CLI and environment
   npx nx run local:configure_env_file
   npx nx run local:configure_github_secrets
   ```

3. **Deploy Infrastructure**
   ```bash
   # Source environment variables
   source .env
   
   # Deploy backend and cluster
   npx nx run setup:terraform-apply
   npx nx run cluster:terraform-apply
   ```

#### Option 2: Manual Setup (Traditional Method)

1. **AWS Credentials**
   ```bash
   aws configure
   ```

2. **Environment Variables**
   Create a `.env` file in the root directory:
   ```bash
   TF_VAR_region=us-east-1
   TF_VAR_account_id=012345678901
   TF_WORKSPACE=dev
   ```

3. **GitHub Secrets**
   Manually set up GitHub repository secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

#### Option 3: Account Change/Reset

When switching to a new AWS account or resetting credentials:

1. **Update Credentials**
   ```bash
   # Update .keys file with new credentials
   vim .keys
   ```

2. **Reconfigure Environment**
   ```bash
   # Reconfigure everything
   npx nx run local:configure_env_file
   npx nx run local:configure_github_secrets
   ```


## 🌐 Deployment

### Automated Deployment (CI/CD)

The repository includes three GitHub Actions workflows:

1. **CI/CD Pipeline** (`ci.yml`) - Automated deployment on push to main branch
2. **PR Validation** (`pr-validation.yml`) - Validates changes in pull requests
3. **Manual Infrastructure** (`manual-infrastructure.yml`) - Manual deployment controls

### Manual Deployment

Use the GitHub Actions "Manual Infrastructure Management" workflow to:

- Plan infrastructure changes
- Apply changes to specific environments
- Destroy infrastructure when needed

## 📚 Documentation

- [Local Package README](packages/local/README.md) - Development environment setup scripts
- [Setup Package README](packages/setup/README.md) - Backend infrastructure details
- [Cluster Package README](packages/cluster/README.md) - K3s cluster details
- [GitHub Actions README](.github/workflows/README.md) - CI/CD pipeline documentation
