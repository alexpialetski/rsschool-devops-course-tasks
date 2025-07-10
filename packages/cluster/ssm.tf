locals {
  services = {
    "ec2messages" : {
      "name" : "com.amazonaws.${data.aws_region.current.id}.ec2messages"
    },
    "ssm" : {
      "name" : "com.amazonaws.${data.aws_region.current.id}.ssm"
    },
    "ssmmessages" : {
      "name" : "com.amazonaws.${data.aws_region.current.id}.ssmmessages"
    }
  }
}

resource "aws_iam_role" "ssm_role" {
  name = "SSMRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_security_group" "ssm_https" {
  name        = "allow_ssm"
  description = "Allow SSM traffic"
  vpc_id      = aws_vpc.k8s_vpc.id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    # cidr_blocks = [for subnet in aws_subnet.private : subnet.cidr_block]
    # use security group instead of cidr_blocks
    security_groups = [aws_security_group.ec2_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "ssm_endpoint" {
  for_each            = local.services
  vpc_id              = aws_vpc.k8s_vpc.id
  service_name        = each.value.name
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.ssm_https.id]
  private_dns_enabled = true
  ip_address_type     = "ipv4"
  subnet_ids          = [for subnet in aws_subnet.public : subnet.id]
}
