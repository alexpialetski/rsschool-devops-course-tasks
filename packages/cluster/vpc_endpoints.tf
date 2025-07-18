locals {
  services = {
    "ec2messages" : "com.amazonaws.${data.aws_region.current.id}.ec2messages",
    "ssm" : "com.amazonaws.${data.aws_region.current.id}.ssm",
    "ssmmessages" : "com.amazonaws.${data.aws_region.current.id}.ssmmessages"
  }
}

################################################################################
# SSM endpoints to enable connection to EC2 instances
################################################################################

resource "aws_security_group" "ssm_https" {
  name        = "allow_ssm"
  description = "Allow SSM traffic"
  vpc_id      = aws_vpc.k8s_vpc.id

  ingress {
    description = "Allow SSM traffic for public subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for subnet in aws_subnet.public : subnet.cidr_block]
  }

  ingress {
    description = "Allow SSM traffic for private subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [for subnet in aws_subnet.private : subnet.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.naming_prefix}-ssm-sg"
  }
}

resource "aws_vpc_endpoint" "ssm_endpoint" {
  for_each            = local.services
  vpc_id              = aws_vpc.k8s_vpc.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  ip_address_type     = "ipv4"

  security_group_ids = [aws_security_group.ssm_https.id]
  subnet_ids         = sort([for subnet in aws_subnet.public : subnet.id])


  depends_on = [aws_subnet.public]
}