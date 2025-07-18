data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "k8s_vpc" {
  cidr_block = var.vpc_cidr

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.naming_prefix}-vpc"
  }
}