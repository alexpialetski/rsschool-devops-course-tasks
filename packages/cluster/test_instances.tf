data "aws_ami" "amazon-linux-2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

variable "sg_ingress_ports" {
  description = "List of ingress ports for the security group"
  type = list(object({
    description = string
    port        = number
  }))
  default = [
    {
      description = "HTTP"
      port        = 80
    },
    {
      description = "HTTPS"
      port        = 443
    }
  ]
}

resource "aws_security_group" "ec2_security_group" {
  description = "Allow traffic for EC2 Webservers"
  vpc_id      = aws_vpc.k8s_vpc.id

  dynamic "ingress" {
    for_each = var.sg_ingress_ports
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

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "SSMInstanceProfile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_instance" "web" {
  count = length(aws_subnet.private)

  ami           = data.aws_ami.amazon-linux-2023.id
  instance_type = "t3.micro"
  #   key_name               = var.instance_key
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  subnet_id              = aws_subnet.private[count.index].id
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name


  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y httpd.x86_64
  systemctl start httpd.service
  systemctl enable httpd.service

  TOKEN=$(curl --request PUT "http://169.254.169.254/latest/api/token" --header "X-aws-ec2-metadata-token-ttl-seconds: 3600")

  instanceId=$(curl -s http://169.254.169.254/latest/meta-data/instance-id --header "X-aws-ec2-metadata-token: $TOKEN")
  instanceAZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone --header "X-aws-ec2-metadata-token: $TOKEN")
  privHostName=$(curl -s http://169.254.169.254/latest/meta-data/local-hostname --header "X-aws-ec2-metadata-token: $TOKEN")
  privIPv4=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 --header "X-aws-ec2-metadata-token: $TOKEN")

  echo "<font face = "Verdana" size = "5">"                               > /var/www/html/index.html
  echo "<center><h1>AWS Linux VM Deployed with Terraform</h1></center>"   >> /var/www/html/index.html
  echo "<center> <b>EC2 Instance Metadata</b> </center>"                  >> /var/www/html/index.html
  echo "<center> <b>Instance ID:</b> $instanceId </center>"               >> /var/www/html/index.html
  echo "<center> <b>AWS Availablity Zone:</b> $instanceAZ </center>"      >> /var/www/html/index.html
  echo "<center> <b>Private Hostname:</b> $privHostName </center>"        >> /var/www/html/index.html
  echo "<center> <b>Private IPv4:</b> $privIPv4 </center>"                >> /var/www/html/index.html
  echo "</font>"                                                          >> /var/www/html/index.html
EOF

  tags = {
    Name = "${local.naming_prefix}-web-${count.index + 1}"
  }
}

