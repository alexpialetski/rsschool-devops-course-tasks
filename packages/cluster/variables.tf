variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones_count" {
  description = "Number of availability zones to use for redundancy"
  type        = number
  default     = 2

  validation {
    condition     = var.availability_zones_count >= 2
    error_message = "At least 2 AZs are required for high availability."
  }
}

variable "control_plane_nodes_count" {
  description = "Number of nodes to use for Kubernetes control plane"
  type        = number
  default     = 1

  validation {
    condition     = var.control_plane_nodes_count >= 1
    error_message = "At least 1 control plane node is required."
  }
}

variable "worker_nodes_count" {
  description = "Number of worker nodes to use in the Kubernetes cluster"
  type        = number
  default     = 2

  validation {
    condition     = var.worker_nodes_count >= 1
    error_message = "At least 1 worker node is required."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}
