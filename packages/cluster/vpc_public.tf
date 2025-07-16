locals {
  number_of_public_subnets = var.availability_zones_config.public
}

################################################################################
# Public Subnet
################################################################################
resource "aws_subnet" "public" {
  count = local.number_of_public_subnets

  vpc_id            = aws_vpc.k8s_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, local.number_of_public_subnets + count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true # This makes public subnet

  tags = {
    Name = "${local.naming_prefix}-public-subnet-${count.index}"
  }
}

################################################################################
# Public Route Table for internet access
################################################################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.k8s_vpc.id

  tags = {
    Name = "${local.naming_prefix}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${local.naming_prefix}-public-rtable"
  }
}

resource "aws_route_table_association" "public_rt_association" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}