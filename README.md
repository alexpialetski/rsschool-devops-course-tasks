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

   Terraform targets (`terraform-init`, `-plan`, `-apply`, `-destroy`, `-validate`, `-fmt`, `-output`) are inferred by the [nx-terraform](https://www.npmjs.com/package/nx-terraform) ([docs](https://alexpialetski.github.io/nx-terraform/)) Nx plugin from the `nx-terraform` metadata in each Terraform project's `project.json`. Use `--configuration=dev|stable` on `cluster` plan/destroy to pick the tfvars file, and run `npx nx sync` after changing Terraform providers/modules to refresh the plugin metadata.

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

## 📚 Documentation

- [Local Package README](packages/local/README.md) - Development environment setup scripts
- [Setup Package README](packages/setup/README.md) - Backend infrastructure details
- [Cluster Package README](packages/cluster/README.md) - K3s cluster details
- [GitHub Actions README](.github/workflows/README.md) - CI/CD pipeline documentation
