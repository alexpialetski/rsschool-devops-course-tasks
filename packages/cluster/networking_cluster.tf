################################################################################
# Subnet and Route Table Configuration for Kubernetes Cluster
################################################################################

resource "aws_subnet" "private" {
  count = var.availability_zones_count

  vpc_id            = aws_vpc.k8s_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = false # This makes private subnet

  tags = {
    Name = "${local.naming_prefix}-private-subnet-${count.index}"
  }
}

resource "aws_route_table" "private" {
  count = length(aws_subnet.private)

  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgateway[count.index].id
  }

  tags = {
    Name = "${local.naming_prefix}-private-rt-${count.index + 1}"
  }
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

locals {
  sg_ingress_ports = [{
    description = "HTTP"
    port        = 80
    },
    {
      description = "HTTPS"
      port        = 443
    }
  ]
}

################################################################################
# Define the security group for EC2 Webservers
################################################################################

resource "aws_security_group" "ec2_security_group" {
  description = "Allow traffic for EC2 Webservers"
  vpc_id      = aws_vpc.k8s_vpc.id

  dynamic "ingress" {
    for_each = local.sg_ingress_ports
    iterator = sg_ingress

    content {
      description = sg_ingress.value["description"]
      from_port   = sg_ingress.value["port"]
      to_port     = sg_ingress.value["port"]
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.naming_prefix}-sg-webserver"
  }
}