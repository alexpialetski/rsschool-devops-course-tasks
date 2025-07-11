terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.2.0"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      Project   = "K3s Cluster"
      Workspace = terraform.workspace
    }
  }
}
