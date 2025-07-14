# RS School DevOps Course Tasks

This repository contains Infrastructure as Code (IaC) solutions for the RS School DevOps Course. The project uses Terraform to provision AWS infrastructure for a Kubernetes cluster using k3s, with an automated CI/CD pipeline built on GitHub Actions and Nx workspace management.

## 🏗️ Architecture Overview

The infrastructure consists of two main components:

1. **Setup Package** (`packages/setup/`) - Creates the AWS S3 backend for Terraform state management
2. **Cluster Package** (`packages/cluster/`) - Provisions a K3s Kubernetes cluster on AWS

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured with appropriate credentials
- Node.js (v20+) and npm
- Terraform (v1.8+)

### Environment Setup

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

### Local Development

1. **Install Dependencies**

   ```bash
   npm install
   ```

2. **Deploy Infrastructure**

   ```bash
   # Deploy backend infrastructure
   npx nx run setup:terraform-apply

   # Deploy K3s cluster
   npx nx run cluster:terraform-apply
   ```

3. **Validate Configuration**

   ```bash
   # Format Terraform files
   npx nx run-many -t terraform-fmt

   # Validate all projects
   npx nx run-many -t terraform-validate
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

- [Setup Package README](packages/setup/README.md) - Backend infrastructure details
- [Cluster Package README](packages/cluster/README.md) - K3s cluster details
- [GitHub Actions README](.github/workflows/README.md) - CI/CD pipeline documentation
