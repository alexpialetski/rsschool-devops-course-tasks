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

### `connect-kubectl`

```bash
npx nx run local:connect-kubectl
# or with custom local port
npx nx run local:connect-kubectl -- 8443
```

- Depends on `cluster:terraform-output` target
- Establishes SSM port forwarding to K3s control plane (remote port 6443)
- Retrieves kubeconfig from AWS Secrets Manager
- Configures kubectl for local access to the K3s cluster
- Outputs: `kubeconfig` and `k3s-session.json`
- Handles Windows and Linux SSM command differences automatically
- **Parameters**:
  - `LOCAL_PORT` (optional): Local port to forward to (default: 6443)

### `disconnect-kubectl`

```bash
npx nx run local:disconnect-kubectl
```

- Terminates SSM port forwarding session
- Cleans up session files and kubeconfig
- Safe to run even if no active session exists

### `test-kubectl-connection`

```bash
npx nx run local:test-kubectl-connection
```

- Tests the current kubectl connection to the K3s cluster
- Validates that kubeconfig and session files exist
- Runs basic kubectl commands to verify cluster accessibility
- Useful for troubleshooting connection issues

## 🔗 K3s Cluster Connection

The local package provides automated connection to the K3s cluster deployed by the `cluster` package:

### How It Works

1. **Terraform Integration**: Reads cluster outputs (`control_plane_instance_ids` and `k3s_kubeconfig_secret_name`) from the cluster package's terraform state
2. **SSM Port Forwarding**: Establishes secure connection to K3s API server via AWS Systems Manager
3. **Kubeconfig Setup**: Retrieves and configures kubeconfig from AWS Secrets Manager
4. **kubectl Ready**: Provides working kubectl configuration for cluster access

### Prerequisites for K3s Connection

- Deployed K3s cluster (run `npx nx run cluster:terraform-apply`)
- AWS CLI configured with appropriate permissions
- kubectl installed and available in PATH
- AWS Session Manager plugin installed

### Usage Examples

```bash
# Connect to K3s cluster (default port 6443)
npx nx run local:connect-kubectl

# Connect to K3s cluster with custom local port
npx nx run local:connect-kubectl -- 8443

# Use kubectl (in a new terminal or after export)
export KUBECONFIG=./packages/local/kubeconfig
kubectl get nodes
kubectl get pods --all-namespaces

# Test the connection
npx nx run local:test-kubectl-connection

# Disconnect when done
npx nx run local:disconnect-kubectl
```

### Direct Script Usage

You can also run the script directly with parameters:

```bash
# Run script directly with default port
cd packages/local
bash connect-kubectl.sh

# Run script with custom port
bash connect-kubectl.sh 8443

# Show help
bash connect-kubectl.sh --help
```

### Windows Usage

For Windows users, the bash scripts work through Git Bash or WSL:

```bash
# Connect to K3s cluster (Windows Git Bash)
cd packages/local
bash connect-kubectl.sh

# Use kubectl on Windows
export KUBECONFIG=$PWD/kubeconfig
kubectl get nodes

# Disconnect
bash disconnect-kubectl.sh
```

### GitHub Actions Integration

The K3s connection functionality is integrated into GitHub Actions workflows:

- **ci.yml**: Deploys the infrastructure with production environment approval
- **deploy-k8s.yml**: Connects to K3s cluster and deploys applications (depends on ci.yml)

The workflows use the nx targets for better maintainability:

```yaml
jobs:
  deploy-k8s:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - name: Connect to K3s Cluster
        run: |
          cd packages/local
          npx nx run local:connect-kubectl
          echo "KUBECONFIG=$PWD/kubeconfig" >> $GITHUB_ENV

      - name: Verify K3s Cluster
        run: |
          cd packages/local
          npx nx run local:test-kubectl-connection

      - name: Deploy Applications
        run: |
          kubectl apply -f k8s/

      - name: Cleanup Connection
        if: always()
        run: |
          cd packages/local
          npx nx run local:disconnect-kubectl
```

### Platform-Specific Considerations

- **Windows**: Uses PowerShell for port checking and different SSM command format
- **Linux/GitHub Actions**: Uses netcat for port checking and JSON parameter format
- **SSM Commands**: Automatically detects platform and uses appropriate command format

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
