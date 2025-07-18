locals {
  number_of_private_subnets = var.availability_zones_config.private
}

################################################################################
# Private subnets and Route Table Configuration for Kubernetes Cluster
################################################################################

resource "aws_subnet" "private" {
  count = local.number_of_private_subnets

  vpc_id = aws_vpc.k8s_vpc.id
  # shifting the CIDR block to avoid overlap with public subnets
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, local.number_of_public_subnets + count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = false # This makes private subnet

  tags = {
    Name = "${local.naming_prefix}-private-subnet-${count.index}"
  }
}

resource "aws_route_table" "private" {
  count = local.number_of_private_subnets

  vpc_id = aws_vpc.k8s_vpc.id

  # Route to NAT instance for internet access 
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.nat_instance[count.index % length(aws_instance.nat_instance)].primary_network_interface_id
  }

  tags = {
    Name = "${local.naming_prefix}-private-rt-${count.index + 1}"
  }
}

resource "aws_route_table_association" "private" {
  count = local.number_of_private_subnets

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
