# Local Package

This package contains automation scripts for local development environment setup and cluster management. It simplifies AWS credential configuration, environment setup, GitHub secrets management, and provides seamless K3s cluster connectivity.

## 📋 Overview

The local package is configured as an Nx project with the following targets:

**Environment Setup:**

- **`configure_aws.sh`** - Configures AWS CLI from a `.keys` file
- **`configure_env_file.sh`** - Generates environment file from AWS configuration
- **`configure_github_secrets.sh`** - Updates GitHub repository secrets

**Cluster Management:**

- **`connect-kubectl.sh`** - Establishes secure K3s cluster connection via SSM

  - Establishes SSM port forwarding to K3s control plane (remote port 6443)
  - Retrieves kubeconfig from AWS Secrets Manager using resource tags
  - Configures kubectl for local access to the K3s cluster
  - Outputs: kubeconfig and k3s-session.json

- **`disconnect-kubectl.sh`** - Cleanly terminates cluster connections

  - Terminates SSM port forwarding session
  - Cleans up session files and kubeconfig

**Utilities:**

- **`update-docs-prompt.sh`** - Documentation update automation

  - Generates documentation update prompts based on git history
  - Analyzes commits since last `readme-checkpoint` tag
  - Creates structured prompts for AI-assisted documentation updates
  - Useful for maintaining up-to-date project documentation

## 🔗 K3s Cluster Connection

The local package provides automated connection to the K3s cluster deployed by the `cluster` package:

### How It Works

1. **Resource Discovery**: Uses AWS resource tags to locate cluster components (no terraform state dependency)
2. **SSM Port Forwarding**: Establishes secure connection to K3s API server via AWS Systems Manager
3. **Kubeconfig Setup**: Retrieves and configures kubeconfig from AWS Secrets Manager
4. **kubectl Ready**: Provides working kubectl configuration for cluster access

### Usage Examples

```bash
# Connect to K3s cluster (default port 6443)
npx nx run local:connect-kubectl

# Use kubectl (in a new terminal or after export)
export KUBECONFIG=./packages/local/kubeconfig
kubectl get nodes

# Disconnect when done
npx nx run local:disconnect-kubectl
```

### GitHub Actions Integration

The K3s connection functionality is integrated into GitHub Actions workflows:

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

      - name: Deploy Applications
        run: |
          kubectl apply -f k8s/

      - name: Cleanup Connection
        if: always()
        run: |
          cd packages/local
          npx nx run local:disconnect-kubectl
```

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
