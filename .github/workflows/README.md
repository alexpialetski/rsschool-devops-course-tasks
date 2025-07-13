# GitHub Actions Configuration

## Required Secrets

Set these secrets in your GitHub repository settings (Settings > Secrets and variables > Actions):

### AWS Configuration
- `AWS_ACCESS_KEY_ID`: AWS access key ID for Terraform operations
- `AWS_SECRET_ACCESS_KEY`: AWS secret access key for Terraform operations

### Optional Secrets
- `NX_CLOUD_ACCESS_TOKEN`: If using Nx Cloud for distributed task execution and caching

## Required Variables

Set these variables in your GitHub repository settings (Settings > Secrets and variables > Actions):

### AWS Configuration
- `AWS_REGION`: AWS region to deploy to (default: us-east-1)

## Terraform Variables

The following Terraform variables are automatically set based on AWS authentication:
- `TF_VAR_region`: Set from AWS_REGION environment variable
- `TF_VAR_account_id`: Taken from outputs of configure-aws-credentials

## Environments

Configure these environments in your GitHub repository settings (Settings > Environments):

### production
- Required reviewers: Set up manual approval for production deployments
- Deployment branches: Only allow deployments from `main` branch

### dev
- No restrictions (optional)

## Workspace Configuration

- **Development**: Uses `dev` workspace
- **Production**: Uses `stable` workspace (triggered from `main` branch)

## Workflow Files Overview

### 1. `ci.yml` - Main CI/CD Pipeline
- **Triggers**: Push to main/develop, PRs
- **Jobs**: 
  - `main`: Format, apply setup (creates backend), plan cluster
  - `security`: Run security scans (Checkov)
  - `deploy`: Deploy cluster infrastructure (setup already applied)
  - `cleanup`: Manual destruction workflow

### 2. `pr-validation.yml` - Pull Request Validation
- **Triggers**: PRs to main/develop
- **Jobs**:
  - `validate`: Apply setup, validate and plan cluster (full deployment flow)
  - `security-scan`: Security scanning with PR comments

### 3. `manual-infrastructure.yml` - Manual Infrastructure Management
- **Triggers**: Manual workflow dispatch
- **Inputs**:
  - `action`: plan/apply/destroy
  - `project`: setup/cluster
  - `environment`: dev/stable

## Composite Actions

### `setup-terraform` Action
Located at `.github/actions/setup-terraform/action.yml`, this composite action consolidates common setup steps:

- **Checkout**: Code checkout with full history
- **Node.js Setup**: Installs Node.js with npm caching
- **Dependencies**: Installs npm dependencies
- **Terraform Setup**: Configures Terraform with specified version
- **AWS Authentication**: Sets up AWS credentials with output enabled
- **Environment Variables**: Sets TF_VAR_region and TF_VAR_account_id from AWS credentials output

**Inputs:**
- `aws-access-key-id`: AWS Access Key ID (required)
- `aws-secret-access-key`: AWS Secret Access Key (required)
- `aws-region`: AWS Region (required)
- `node-version`: Node.js version (optional, default: '20')
- `terraform-version`: Terraform version (optional, default: '~1.8.0')

**Outputs:**
- `aws-account-id`: AWS Account ID retrieved from configure-aws-credentials action
- `aws-region`: AWS Region being used

## Nx Integration

The workflows leverage your Nx configuration for:

- **Critical Dependency**: Setup project creates the S3 backend bucket that cluster project needs
- **Sequential Execution**: Always applies setup first, then plans/applies cluster
- **Parallel Execution**: Runs tasks in parallel where possible (except for the setup→cluster dependency)
- **Caching**: Uses Nx caching for faster builds
- **Dependencies**: Respects project dependencies (setup → cluster)

**Note**: The workflows are optimized for temporary AWS accounts and handle the critical dependency where setup creates the backend storage for cluster's Terraform state.

## Security Features

- **Terraform State**: Securely stored in AWS S3 with backend configuration
- **Security Scanning**: Checkov and TFSec for Terraform security
- **PR Comments**: Automated security findings in PR comments
- **Environment Protection**: Manual approval for production deployments

## Usage Examples

### Deploy to Development
```bash
# Automatically happens on push to develop branch
git push origin develop
```

### Deploy to Production
```bash
# Automatically happens on push to main branch (after approval)
git push origin main
```

### Manual Infrastructure Management
1. Go to Actions tab in GitHub
2. Select "Manual Infrastructure Management"
3. Click "Run workflow"
4. Select action, project, and environment
5. Click "Run workflow"

### Emergency Destruction
1. Go to Actions tab in GitHub
2. Select "Manual Infrastructure Management"
3. Select "destroy" action
4. Select project and environment
5. Confirm and run

## Best Practices

1. **Always create PRs** for infrastructure changes
2. **Review security scan results** before merging
3. **Use environments** for production deployments
4. **Monitor maintenance reports** for resource cleanup
5. **Keep secrets updated** and rotate regularly
6. **Fresh deployments**: The pipeline is optimized for temporary AWS accounts and will always deploy both setup and cluster infrastructure

## Temporary AWS Account Optimization

The workflows are designed for scenarios where AWS accounts are temporary (like KodeKloud):

- **Backend Creation**: Setup project creates the S3 backend bucket that cluster needs
- **Correct Order**: Always applies setup first, then plans/applies cluster
- **Fresh state**: Each deployment starts with a clean infrastructure state
- **Dependency respect**: Handles the critical setup→cluster backend dependency
- **Simplified flow**: No complex conditional logic based on changed files

## Troubleshooting

### Common Issues

1. **Terraform state lock**: Wait for running operations to complete
2. **AWS credentials**: Verify secrets are set correctly
3. **Backend dependency**: Setup must complete before cluster can initialize
4. **Fresh account**: Each deployment creates new infrastructure from scratch
5. **Dependencies**: Setup creates the S3 backend bucket that cluster requires

### Debugging Steps

1. Check workflow logs in GitHub Actions
2. Verify environment variables and secrets
3. Run commands locally with same configuration
4. Check AWS CloudFormation events if deployment fails
