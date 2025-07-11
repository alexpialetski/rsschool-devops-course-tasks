terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
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

provider "tls" {}
