# Local Package

The local package provides automation scripts for local development environment setup. It simplifies the process of configuring AWS credentials, environment variables, and GitHub secrets for infrastructure development.

## 📋 Overview

This package contains three main scripts that work together to set up your local development environment:

1. **`configure_aws.sh`** - Configures AWS CLI from a `.keys` file
2. **`configure_env_file.sh`** - Generates environment file from AWS configuration
3. **`configure_github_secrets.sh`** - Updates GitHub repository secrets

## 🚀 Quick Start

### Prerequisites

- AWS CLI installed and available in PATH
- GitHub CLI (`gh`) installed and authenticated
- Git repository with GitHub remote configured

### Basic Usage

1. **Create a `.keys` file** with your AWS credentials:
   ```bash
   # .keys file content
   AWS_ACCESS_KEY_ID=your-access-key-id
   AWS_SECRET_ACCESS_KEY=your-secret-access-key
   AWS_DEFAULT_REGION=us-east-1
   ```

2. **Run the complete setup** using Nx:
   ```bash
   npx nx run local:configure_env_file
   npx nx run local:configure_github_secrets
   ```


## 🔧 Nx Integration

The local package is configured as an Nx project with the following targets:

### `configure_aws`
```bash
npx nx run local:configure_aws
```
- Runs `configure_aws.sh` with `.keys` file from workspace root
- Default keys file: `{workspaceRoot}/.keys`

### `configure_env_file`
```bash
npx nx run local:configure_env_file
```
- Depends on `configure_aws` target
- Runs `configure_env_file.sh` with `.env` file in workspace root
- Default env file: `{workspaceRoot}/.env`

### `configure_github_secrets`
```bash
npx nx run local:configure_github_secrets
```
- Depends on `configure_aws` target
- Runs `configure_github_secrets.sh` with no additional arguments

## 🔐 Security Considerations

### `.keys` File Security
- **Never commit** the `.keys` file to version control
- Store it in a secure location with restricted permissions
- Use temporary credentials when possible
- Rotate credentials regularly

### GitHub Secrets
- Secrets are encrypted and only accessible to GitHub Actions
- Use environment-specific secrets for different deployment stages
- Regularly audit and rotate secrets

### AWS Credentials
- Use IAM roles with least-privilege permissions
- Enable MFA for AWS accounts when possible
- Monitor AWS CloudTrail for credential usage
