# Cluster Package

This package provisions a production-ready K3s Kubernetes cluster on AWS with high availability, security, and scalability features.

## 📋 Overview

The cluster package creates a complete K3s Kubernetes cluster with:

- **VPC Infrastructure** with public and private subnets across multiple AZs
- **K3s Cluster** with control plane and agent nodes
- **Load Balancer** (WIP) for external access and high availability
- **Security Groups** with proper network controls
- **IAM Roles** for AWS service integration
- **VPC Endpoints** for secure AWS service access

## 🏗️ Infrastructure Components

### Networking Infrastructure

#### VPC and Subnets (`networking_vpc.tf`)

- **VPC**: Custom VPC with DNS support enabled
- **Public Subnets**: For load balancer and NAT gateway
- **Private Subnets**: For K3s nodes (secure placement)
- **Availability Zones**: Configurable count for high availability

#### NAT Gateway (`networking_nat_gateway.tf`)

- **Purpose**: Internet access for private subnet resources
- **Placement**: In public subnets with Elastic IP addresses
- **Routing**: Configured for private subnet internet access

#### VPC Endpoints (`networking_vpc.tf`)

- **SSM Endpoints**: For secure instance management
- **Services**: EC2 Messages, SSM, SSM Messages
- **Security**: Endpoint-specific security groups

### Compute Infrastructure

#### EC2 Instances (`nodes_instances.tf`)

- **Control Plane**: 1 t3.medium instance (configurable)
- **Agent Nodes**: 2 t3.micro instances (configurable)
- **Placement**: Private subnets across multiple AZs
- **AMI**: Latest Amazon Linux 2 AMI

#### Load Balancer (WIP) (`nodes_load_balancer.tf`)

- **Type**: Application Load Balancer (ALB)
- **Placement**: Public subnets for external access
- **Target Groups**: Health checks for K3s API server
- **Listeners**: HTTPS/HTTP forwarding to K3s API

### Security Infrastructure

#### Security Groups (WIP) (`security.tf`)

- **Control Plane SG**: K3s API server access (port 6443)
- **Agent Node SG**: Inter-node communication
- **Load Balancer SG**: External HTTPS/HTTP access
- **Database SG**: If external database is used

#### IAM Roles (`nodes_iam.tf`)

- **EC2 Instance Role**: For AWS service access
- **SSM Permissions**: For instance management
- **ECR Permissions (WIP)**: For container image access (if needed)

### K3s Configuration

#### K3s Server (`nodes_k3s.tf`)

- **Token Management**: Stored in AWS Secrets Manager
- **Installation**: Automated via user data scripts
- **Configuration**: Embedded etcd, API server binding

#### K3s Agent (`nodes_k3s.tf`)

- **Node Registration**: Automatic joining to cluster
- **Token Retrieval**: From AWS Secrets Manager
- **Configuration**: Container runtime and networking

## 🔧 Configuration

### Variables (`variables.tf`)

#### VPC Configuration

```hcl
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones_count" {
  description = "Number of availability zones"
  type        = number
  default     = 1
}
```

#### Control Plane Configuration

```hcl
variable "control_plane_config" {
  description = "Configuration for control plane nodes"
  type = object({
    nodesNumber  = number
    instanceType = string
  })
  default = {
    nodesNumber  = 1
    instanceType = "t3.medium"
  }
}
```

#### Agent Nodes Configuration

```hcl
variable "agent_nodes_config" {
  description = "Configuration for agent nodes"
  type = object({
    nodesNumber  = number
    instanceType = string
  })
  default = {
    nodesNumber  = 2
    instanceType = "t3.micro"
  }
}
```

### Environment-Specific Configuration

#### Stable Environment (`tfvars/stable.tfvars`)

```hcl
availability_zones_count = 2
control_plane_config = {
  nodesNumber  = 1
  instanceType = "t3.medium"
}
agent_nodes_config = {
  nodesNumber  = 2
  instanceType = "t3.micro"
}
```

## 🔐 Security Features

### Network Security

- **Private Subnets**: K3s nodes in private subnets only
- **Security Groups**: Restrictive ingress/egress rules
- **VPC Endpoints**: Secure AWS service access without internet

### Access Control

- **IAM Roles**: Least-privilege access for instances
- **SSH Keys**: Inter-communication between nodes
- **SSM access**: Access to EC2 instances via SSM agent
- **API Access**: Load balancer with security groups

### Secrets Management

- **K3s Token**: Stored in AWS Secrets Manager
- **Encryption**: At-rest encryption for secrets

## 🔄 Dependencies

### Upstream Dependencies

- **Setup Package**: Provides backend configuration
- **AWS Provider**: Requires AWS credentials

## 📊 Outputs

### Cluster Information

- **Load Balancer DNS (WIP)**: External access endpoint

### Access Information

- **API Server (WIP)**: Accessible via load balancer
- **Node IPs (WIP)**: Private IP addresses

## 🛠️ Troubleshooting

### Common Issues

1. **Backend Configuration Missing**

   - **Cause**: Setup package not applied
   - **Solution**: Run `npx nx run setup:terraform-apply` first

2. **K3s Cluster Not Ready**

   - **Cause**: Network connectivity or token issues
   - **Solution**: Check security groups and secrets manager

3. **Load Balancer Health Check Failures**
   - **Cause**: K3s API server not accessible
   - **Solution**: Verify security groups and K3s configuration

## 📈 Monitoring and Observability (WIP)

### CloudWatch Integration

- **Instance Metrics**: CPU, memory, disk usage
- **Load Balancer Metrics**: Request count, latency
- **Custom Metrics**: K3s cluster health

### Logging

- **Instance Logs**: Available through SSM
- **Application Logs**: K3s container logs
- **Access Logs**: Load balancer access logs

## 📚 Related Documentation

- [Setup Package README](../setup/README.md)
- [GitHub Actions README](../../.github/workflows/README.md)
- [Root README](../../README.md)
- [K3s Documentation](https://k3s.io/)
