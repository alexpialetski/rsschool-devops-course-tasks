# Setup Terraform Composite Action

This composite action provides a standardized way to set up the complete Terraform environment with AWS credentials and Node.js across all workflows.

## What it does

1. **Checkout**: Checks out the repository code with full history
2. **Node.js Setup**: Installs Node.js with npm caching enabled
3. **Dependencies**: Installs npm dependencies using `npm ci`
4. **Terraform Setup**: Configures Terraform with the specified version
5. **AWS Authentication**: Sets up AWS credentials for Terraform operations with output enabled
6. **Environment Variables**: Sets `TF_VAR_region` and `TF_VAR_account_id` automatically from AWS credentials output

## Usage

```yaml
steps:
  - name: Setup Terraform Environment
    uses: ./.github/actions/setup-terraform
    with:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      aws-region: ${{ env.AWS_REGION }}
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `aws-access-key-id` | AWS Access Key ID | Yes | - |
| `aws-secret-access-key` | AWS Secret Access Key | Yes | - |
| `aws-region` | AWS Region | Yes | - |
| `node-version` | Node.js version | No | `20` |
| `terraform-version` | Terraform version | No | `~1.8.0` |

## Outputs

| Output | Description |
|--------|-------------|
| `aws-account-id` | AWS Account ID retrieved from configure-aws-credentials action |
| `aws-region` | AWS Region being used |

## Benefits

- **Consistency**: All workflows use the same setup process
- **Maintainability**: Single place to update versions and configurations
- **Reduced Duplication**: Eliminates repetitive setup steps across workflows
- **Reliability**: Standardized error handling and environment setup
- **Efficiency**: Uses built-in AWS credentials output instead of separate STS calls

## Example with Outputs

```yaml
steps:
  - name: Setup Terraform Environment
    id: setup
    uses: ./.github/actions/setup-terraform
    with:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      aws-region: ${{ env.AWS_REGION }}
      
  - name: Use outputs
    run: |
      echo "AWS Account ID: ${{ steps.setup.outputs.aws-account-id }}"
      echo "AWS Region: ${{ steps.setup.outputs.aws-region }}"
```
