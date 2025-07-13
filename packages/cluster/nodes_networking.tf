################################################################################
# Private subnets and Route Table Configuration for Kubernetes Cluster
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

################################################################################
# Define the security group for k8s nodes
################################################################################

resource "aws_security_group" "node_security_group" {
  description = "Allow traffic for EC2 kubernetes nodes"
  vpc_id      = aws_vpc.k8s_vpc.id

  ############################
  # INGRESS RULES
  ############################

  # ingress {
  #   description     = "Allow incoming HTTP connections from Load Balancer"
  #   from_port       = 80
  #   to_port         = 80
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.aws-sg-load-balancer.id]
  # }

  # ingress {
  #   description     = "Allow incoming HTTPS connections from Load Balancer"
  #   from_port       = 443
  #   to_port         = 443
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.aws-sg-load-balancer.id]
  # }

  ingress {
    description = "Allow incoming SSH connections from nodes in the same cluster"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "K3s supervisor and Kubernetes API Server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Flannel VXLAN traffic"
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    self        = true
  }

  ingress {
    description = "Kubelet metrics"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    self        = true
  }

  ############################
  # EGRESS RULES
  ############################

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.naming_prefix}-sg-node"
  }
}