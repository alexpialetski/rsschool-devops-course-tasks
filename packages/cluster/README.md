# Cluster Package

This package provisions a production-ready K3s Kubernetes cluster on AWS with high availability, security, and scalability features.

## 📋 Overview

The cluster package creates a complete K3s Kubernetes cluster with:

- **VPC Infrastructure** with public and private subnets across multiple AZs
- **K3s Cluster** with control plane and agent nodes
- **NAT Instance** for cost-effective internet access in private subnets
- **Security Groups** with proper network controls
- **IAM Roles** with resource tagging for service discovery
- **VPC Endpoints** for secure AWS service access
- **Secrets Management** for K3s tokens and kubeconfig

## 🏗️ Infrastructure Components

### Networking Infrastructure

#### VPC and Subnets (`networking_vpc.tf`)

- **VPC**: Custom VPC with DNS support enabled
- **Public Subnets**: For load balancer and NAT instance
- **Private Subnets**: For K3s nodes (secure placement)
- **Availability Zones**: Configurable count for high availability

#### NAT Instance (`vpc_nat_instance.tf`)

- **Purpose**: Cost-effective internet access for private subnet resources
- **Placement**: In public subnets with Elastic IP addresses
- **Instance Type**: Configurable (default: t3.micro for cost optimization)
- **Routing**: Configured for private subnet internet access
- **Access**: Instances accessed via SSM (no SSH access required)
- **Security**: Allows traffic from private subnets only

##### NAT Instance vs NAT Gateway

**Benefits of NAT Instance:**

- **Cost-effective**: ~$3.50/month (t3.micro) vs ~$32/month (NAT Gateway)
- **Customizable**: Full control over instance configuration
- **Monitoring**: Standard EC2 monitoring and logging capabilities

**Trade-offs:**

- **Availability**: Single point of failure (mitigated by fault-tolerant architecture)
- **Maintenance**: Requires OS updates and monitoring
- **Performance**: Lower throughput compared to NAT Gateway

#### VPC Endpoints (`vpc_endpoints.tf`)

- **SSM Endpoints**: For secure instance management
- **Services**: EC2 Messages, SSM, SSM Messages
- **Security**: Endpoint-specific security groups

### Compute Infrastructure

#### EC2 Instances (`nodes_instances.tf`)

- **Control Plane**: 1 instance (configurable count and type)
- **Agent Nodes**: 2 instances (configurable count and type)
- **Placement**: Private subnets across multiple AZs
- **AMI**: Latest Amazon Linux 2 AMI
- **Tagging**: Comprehensive resource tags for service discovery

#### Load Balancer (WIP) (`nodes_load_balancer.tf`)

- **Type**: Application Load Balancer (ALB) - planned for future implementation
- **Purpose**: External access and high availability for K3s API server

### Security Infrastructure

#### Security Groups (WIP) (`security.tf`)

- **Control Plane SG**: K3s API server access (port 6443)
- **Agent Node SG**: Inter-node communication
- **Load Balancer SG**: External HTTPS/HTTP access
- **Database SG**: If external database is used

#### IAM Roles (`nodes_iam.tf`)

- **EC2 Instance Role**: For AWS service access with workspace-specific naming
- **SSM Permissions**: For instance management and secure access
- **Resource Tagging**: Enables service discovery by external tools

### K3s Configuration

#### K3s Server (`nodes_k3s.tf`)

- **Token Management**: Stored in AWS Secrets Manager with proper tagging
- **Kubeconfig Storage**: Automatically stored as AWS secret for external access
- **Installation**: Automated via user data scripts
- **Configuration**: Embedded etcd, API server binding

#### K3s Agent (`nodes_k3s.tf`)

- **Node Registration**: Automatic joining to cluster
- **Token Retrieval**: From AWS Secrets Manager
- **Configuration**: Container runtime and networking

## 🔧 Environment-Specific Configuration

#### Stable Environment (`tfvars/stable.tfvars`)

```hcl
availability_zones_config = {
  public  = 1
  private = 2
}
control_plane_config = {
  nodesNumber  = 1
  instanceType = "t3.small"
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

- **K3s Token**: Stored in AWS Secrets Manager with workspace-specific naming
- **Kubeconfig**: Automatically generated and stored as AWS secret
- **SSH Keys**: Inter-node communication keys stored as secrets
- **Encryption**: At-rest encryption for all secrets

## 🔄 Dependencies

### Upstream Dependencies

- **Setup Package**: Provides backend configuration
- **AWS Provider**: Requires AWS credentials

## 📊 Outputs

### Cluster Information

- **Control Plane Instances**: Instance IDs with proper tagging for service discovery
- **Kubeconfig Secret**: AWS Secrets Manager secret name for external access

### Access Information

- **API Server**: Accessible via SSM port forwarding (no public access)
- **Instance Management**: Via AWS Systems Manager (no SSH keys required)

## 🛠️ Troubleshooting

### Common Issues

1. **Backend Configuration Missing**

   - **Cause**: Setup package not applied
   - **Solution**: Run `npx nx run setup:terraform-apply` first

2. **K3s Connection Issues**
   - **Cause**: Network connectivity or secrets access issues
   - **Solution**: Check security groups, VPC endpoints, and secrets manager permissions

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
