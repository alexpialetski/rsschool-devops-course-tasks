# Setup Package

This package creates the foundational AWS infrastructure required for the Terraform backend state management.

> Nx targets for this package (`terraform-init`, `-plan`, `-apply`, `-destroy`, `-validate`, `-fmt`, `-output`) are inferred by the [nx-terraform](https://www.npmjs.com/package/nx-terraform) ([docs](https://alexpialetski.github.io/nx-terraform/)) plugin. This project is declared as a `backend` project (`metadata["nx-terraform"].projectType` in `project.json`); `cluster` points to it via `terraform-init` `metadata.backendProject`.

## 📋 Overview

The setup package creates foundational AWS infrastructure for Terraform state management:

- **S3 Bucket** for Terraform state storage with versioning and object lock
- **Backend Configuration** file generation for cluster package initialization
- **Bucket Existence Validation** to handle temporary AWS account scenarios

## 🏗️ Resources Created

### S3 Bucket (`aws_s3_bucket.tf_state`)

- **Purpose**: Stores Terraform state for the cluster infrastructure
- **Features**:
  - Versioning enabled for state history
  - Object lock enabled for state protection
  - Force destroy enabled for temporary accounts
- **Naming**: `tf-state-{account-id}-{region}`

### Backend Configuration (`local_file.backend_config`)

- **Purpose**: Generates `backend.config` file for cluster initialization
- **Content**: S3 bucket name, key, and region configuration
- **Usage**: Referenced by cluster package Terraform initialization

### Bucket Existence Check (`data.external.check_bucket`)

- **Purpose**: Prevents resource conflicts in temporary AWS accounts
- **Script**: `scripts/check_bucket.sh`
- **Logic**: Only creates bucket if it doesn't already exist

## 🔐 Security Considerations

### S3 Bucket Security

- **Versioning**: Enabled to track state changes
- **Object Lock**: Prevents accidental state deletion
- **Access Control**: Controlled through IAM policies

### Additional Security

For production environments, consider:

- KMS encryption for S3 bucket
- Bucket policies for access control
- VPC endpoints for S3 access
- **Lifecycle Policies**: Can be configured for state retention
- **Monitoring**: CloudTrail logging for audit and compliance

## 🔄 Dependencies

- **Upstream**: AWS Provider configuration
- **Downstream**: Cluster package backend initialization

## 📊 Outputs

- **backend.config**: Backend configuration for cluster package Terraform initialization
- **S3 bucket**: Terraform state storage with versioning and object lock enabled

## 📚 Related Documentation

- [Cluster Package README](../cluster/README.md)
- [GitHub Actions README](../../.github/workflows/README.md)
- [Root README](../../README.md)
