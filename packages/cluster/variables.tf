variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones_config" {
  description = "Configuration for number of availability zones for public and private subnets"
  type = object({
    public  = number
    private = number
  })

  validation {
    condition     = var.availability_zones_config.public >= 1
    error_message = "At least 1 public AZ is required."
  }
  validation {
    condition     = var.availability_zones_config.private >= 1
    error_message = "At least 1 private AZ is required."
  }
}

variable "control_plane_config" {
  description = "Configuration for Kubernetes control plane nodes"
  type = object({
    nodesNumber  = number
    instanceType = string
  })

  validation {
    condition     = var.control_plane_config.nodesNumber == 1
    error_message = "For now HA cluster with embedded etcd is not supported."
  }
  validation {
    condition     = var.control_plane_config.nodesNumber % 2 == 1
    error_message = "Control plane nodes count must be an odd number for high availability."
  }
  validation {
    condition     = can(regex("^t3\\.(small|medium|large|xlarge|2xlarge)$", var.control_plane_config.instanceType))
    error_message = "Control plane nodes instance type must be t3.medium or larger."
  }
}

variable "agent_nodes_config" {
  description = "Configuration for Kubernetes agent nodes"
  type = object({
    nodesNumber  = number
    instanceType = string
  })

  validation {
    condition     = var.agent_nodes_config.nodesNumber >= 1
    error_message = "At least 1 agent node is required."
  }
  validation {
    condition     = can(regex("^t3\\.(micro|small|medium|large|xlarge|2xlarge)$", var.agent_nodes_config.instanceType))
    error_message = "Agent node instance type must be t3.micro or larger."
  }
}
