locals {
  number_of_nat_instances = local.number_of_public_subnets
}

################################################################################
# NAT Instance Security Group
################################################################################

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
# Elastic IP for NAT Instance
################################################################################

resource "aws_eip" "nat_instance_eip" {
  count = local.number_of_nat_instances

  tags = {
    Name = "${local.naming_prefix}-nat-instance-eip-${count.index}"
  }
}

# Associate Elastic IP with NAT Instance
resource "aws_eip_association" "nat_instance_eip_association" {
  count = length(aws_eip.nat_instance_eip)

  instance_id   = aws_instance.nat_instance[count.index].id
  allocation_id = aws_eip.nat_instance_eip[count.index].id
}

################################################################################
# NAT Instance Configuration
################################################################################


data "template_file" "nat_forwarding" {
  template = file("${path.module}/templates/nat_forwarding.sh.tpl")
}

resource "aws_instance" "nat_instance" {
  count = local.number_of_nat_instances

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
