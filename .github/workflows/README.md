# GitHub Actions Configuration

This document describes the CI/CD pipeline configuration for the RS School DevOps Course infrastructure deployment. The pipeline automates the deployment of a K3s Kubernetes cluster on AWS using Terraform and Nx workspace management.

The workflows are designed for scenarios where AWS accounts are temporary (like KodeKloud).

## 📋 Overview

The CI/CD pipeline consists of three main workflows:

1. **CI/CD Pipeline** (`ci.yml`) - Automated deployment and infrastructure management
2. **PR Validation** (`pr-validation.yml`) - Pull request validation with security scanning
3. **Manual Infrastructure** (`manual-infrastructure.yml`) - Manual deployment controls

## 🔧 Required Configuration

### Secrets

Configure these secrets in your GitHub repository (Settings > Secrets and variables > Actions):

#### AWS Configuration

- `AWS_ACCESS_KEY_ID`: AWS access key ID for Terraform operations
- `AWS_SECRET_ACCESS_KEY`: AWS secret access key for Terraform operations

#### Optional Secrets

- `NX_CLOUD_ACCESS_TOKEN`: Nx Cloud token for distributed task execution and caching

### Variables

Configure these variables in your GitHub repository (Settings > Secrets and variables > Actions):

#### AWS Configuration

- `AWS_REGION`: AWS region for deployment (default: `us-east-1`)

### Environment Variables

The following Terraform variables are automatically configured:

- `TF_VAR_region`: Set from `AWS_REGION` variable
- `TF_VAR_account_id`: Retrieved from AWS credentials during authentication

## 🌍 Environment Configuration

### GitHub Environments

Configure these environments in your repository (Settings > Environments):

#### `production`

- **Purpose**: Production deployments from `main` branch
- **Protection Rules**:
  - Required reviewers for manual approval
  - Deployment branches: Only `main` branch
  - Environment secrets: Production AWS credentials

#### `dev`

- **Purpose**: Development deployments and testing
- **Protection Rules**: Optional, can be left unrestricted
- **Usage**: Manual deployments and testing

### Terraform Workspaces

- **Production**: Uses `default` workspace (triggered from `main` branch)
- **Development**: Uses `dev` workspace (for manual deployments)

## 🚀 Workflow Details

### 1. CI/CD Pipeline (`ci.yml`)

**Trigger**: Push to `main` branch

**Jobs**:

#### `main` Job

- **Purpose**: Infrastructure validation and planning
- **Steps**:
  1. Checkout code with full history
  2. Setup Terraform environment (composite action)
  3. Plan cluster infrastructure with stable configuration
  4. Upload Terraform plans as artifacts

#### `deploy` Job

- **Purpose**: Deploy infrastructure to production
- **Dependencies**: Requires `main` job to complete
- **Environment**: `production` (manual approval required)
- **Steps**:
  1. Checkout code
  2. Setup Terraform environment
  3. Download Terraform plans
  4. Apply cluster infrastructure

#### `cleanup` Job

- **Purpose**: Destroy infrastructure (manual trigger only)
- **Trigger**: `workflow_dispatch` event
- **Environment**: `production`
- **Steps**:
  1. Setup Terraform environment
  2. Destroy cluster infrastructure
  3. Destroy setup infrastructure

### 2. PR Validation (`pr-validation.yml`)

**Trigger**: Pull requests to `main` branch

**Permissions**:

- `contents: read`
- `pull-requests: write`
- `issues: write`

**Jobs**:

#### `validate` Job

- **Purpose**: Validate infrastructure changes
- **Steps**:
  1. Checkout code
  2. Setup Terraform environment
  3. Validate cluster configuration
  4. Plan infrastructure changes
  5. Comment on PR with plan results (WIP)

#### `security-scan` Job

- **Purpose**: Security scanning of infrastructure code
- **Tools**:
  - **Checkov**: Infrastructure security scanning
  - **TFSec**: Terraform security analysis
- **Output**: Security findings as PR comments

### 3. Manual Infrastructure (`manual-infrastructure.yml`)

**Trigger**: Manual workflow dispatch

**Inputs**:

- `action`: Action to perform (`plan`, `apply`, `destroy`)
- `project`: Target project (`setup`, `cluster`)
- `environment`: Target environment (`dev`, `default`)

**Jobs**:

#### `infrastructure` Job

- **Purpose**: Manual infrastructure management
- **Environment**: Dynamic based on input
- **Steps**:
  1. Checkout code
  2. Setup Terraform environment
  3. Execute specified Terraform action
  4. Comment on manual run status

## 🔨 Composite Actions

### `setup-terraform` Action

**Location**: `.github/actions/setup-terraform/action.yml`

**Purpose**: Consolidates common setup steps for all workflows

**Inputs**:

- `aws-access-key-id`: AWS Access Key ID (required)
- `aws-secret-access-key`: AWS Secret Access Key (required)
- `aws-region`: AWS Region (required)
- `node-version`: Node.js version (optional, default: '20')
- `terraform-version`: Terraform version (optional, default: '~1.8.0')
- `skip-setup-apply`: Skip setup infrastructure deployment (optional, default: 'false')

**Outputs**:

- `aws-account-id`: AWS Account ID from credentials
- `aws-region`: AWS Region being used

**Steps**:

1. **Node.js Setup**: Install Node.js with npm caching
2. **Dependencies**: Install npm dependencies
3. **Nx Setup**: Configure Nx for affected commands
4. **Terraform Setup**: Install specified Terraform version
5. **AWS Configuration**: Set up AWS credentials and environment
6. **Terraform Variables**: Set TF_VAR_region and TF_VAR_account_id
7. **Format Check**: Validate Terraform code formatting
8. **Setup Validation**: Validate setup infrastructure
9. **Setup Apply**: Deploy setup infrastructure (creates backend)

## 🔗 Nx Integration

### Workspace Configuration

The workflows leverage Nx workspace features:

- **Project Dependencies**: Setup → Cluster dependency management
- **Task Caching**: Faster execution with Nx caching
- **Parallel Execution (WIP)**: Run independent tasks in parallel
- **Affected Commands (WIP)**: Only process changed projects

### Task Execution

**Terraform Tasks**:

- `terraform-init`: Initialize Terraform with backend
- `terraform-plan`: Plan infrastructure changes
- `terraform-apply`: Apply infrastructure changes
- `terraform-validate`: Validate configuration
- `terraform-fmt`: Format Terraform code
- `terraform-destroy`: Destroy infrastructure

## 🔐 Security Features

### Pipeline Security

- **Security Scanning**: Automated with Checkov and TFSec
- **PR Comments**: Security findings reported in pull requests
- **Environment Protection**: Manual approval for production deployments
- **Credential Management**: AWS credentials stored as GitHub secrets

### Access Control

- **IAM Roles**: Least-privilege access for AWS resources
- **GitHub Environments**: Environment-specific access controls
- **Branch Protection (WIP)**: Deployment restrictions by branch

## 🛠️ Manual Deployment

1. Navigate to GitHub repository
2. Go to **Actions** tab
3. Select **Manual Infrastructure Management**
4. Click **Run workflow**
5. Configure parameters:
   - Action: `plan`, `apply`, or `destroy`
   - Project: `setup` or `cluster`
   - Environment: `dev` or `default`
6. Click **Run workflow**

## Best Practices

1. **Always create PRs** for infrastructure changes
2. **Review security scan results** before merging
3. **Use environments** for production deployments
4. **Keep secrets updated** and rotate regularly
5. **Fresh deployments**: The pipeline is optimized for temporary AWS accounts and will always deploy both setup and cluster infrastructure

## 📚 Related Documentation

- [Setup Package README](../packages/setup/README.md)
- [Cluster Package README](../packages/cluster/README.md)
- [Root README](../README.md)
- [Nx Documentation](https://nx.dev/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
