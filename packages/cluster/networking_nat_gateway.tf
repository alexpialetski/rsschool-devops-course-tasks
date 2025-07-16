################################################################################
# Public Subnet
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
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.k8s_vpc.id

  tags = {
    Name = "${local.naming_prefix}-igw"
  }
}

################################################################################
# Public Route Table for internet access
################################################################################

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

################################################################################
# NAT Instance Security Group
################################################################################

# Security Group for NAT Instance
resource "aws_security_group" "nat_instance_sg" {
  name        = "${local.naming_prefix}-nat-instance-sg"
  description = "Security group for NAT instance"
  vpc_id      = aws_vpc.k8s_vpc.id

  ingress {
    description = "Allow all inbound traffic from private subnets"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [for subnet in aws_subnet.private : subnet.cidr_block]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.naming_prefix}-nat-instance-sg"
  }
}

################################################################################
# NAT Instance IAM role
################################################################################

resource "aws_iam_role" "nat_instance_role" {
  name = "${local.naming_prefix}-nat-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.naming_prefix}-nat-instance-role"
  }
}

resource "aws_iam_role_policy_attachment" "nat_instance_ssm_policy" {
  role       = aws_iam_role.nat_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "nat_instance_profile" {
  name = "${local.naming_prefix}-nat-instance-profile"
  role = aws_iam_role.nat_instance_role.name

  tags = {
    Name = "${local.naming_prefix}-nat-instance-profile"
  }
}

################################################################################
# NAT Instance Configuration
################################################################################

resource "aws_eip" "nat_instance_eip" {
  count = var.availability_zones_count

  tags = {
    Name = "${local.naming_prefix}-nat-instance-eip-${count.index}"
  }
}

# Associate Elastic IP with NAT Instance
resource "aws_eip_association" "nat_instance_eip_association" {
  count = var.availability_zones_count

  instance_id   = aws_instance.nat_instance[count.index].id
  allocation_id = aws_eip.nat_instance_eip[count.index].id
}


data "template_file" "nat_forwarding" {
  template = file("${path.module}/templates/nat_forwarding.sh.tpl")
}

resource "aws_instance" "nat_instance" {
  count = var.availability_zones_count

  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public[count.index].id
  vpc_security_group_ids = [aws_security_group.nat_instance_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.nat_instance_profile.name
  user_data              = data.template_file.nat_forwarding.rendered

  # Disable source/destination check (required for NAT functionality)
  source_dest_check = false

  tags = {
    Name = "${local.naming_prefix}-nat-instance-${count.index}"
    Type = "NAT"
  }

  lifecycle {
    create_before_destroy = true
  }
}
