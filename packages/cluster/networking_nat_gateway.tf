################################################################################
# Public Subnet and NAT Gateway for internet access
################################################################################
resource "aws_subnet" "public" {
  count = var.availability_zones_count

  vpc_id            = aws_vpc.k8s_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, var.availability_zones_count + count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true # This makes public subnet

  tags = {
    Name = "${local.naming_prefix}-public-subnet-${count.index}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.k8s_vpc.id

  tags = {
    Name = "${local.naming_prefix}-igw"
  }
}

resource "aws_eip" "eip_natgw" {
  count = length(aws_subnet.public)
}

resource "aws_nat_gateway" "natgateway" {
  count = length(aws_eip.eip_natgw)

  allocation_id = aws_eip.eip_natgw[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${local.naming_prefix}-nat-gw-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.igw]
}

################################################################################
# Public Route Table for internet access
################################################################################

resource "aws_route_table" "public_route_table" {
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
  route_table_id = aws_route_table.public_route_table.id
}
