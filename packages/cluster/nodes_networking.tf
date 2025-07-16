################################################################################
# Define the security group for k8s nodes
################################################################################

resource "aws_security_group" "node_security_group" {
  description = "Allow traffic for EC2 kubernetes nodes"
  vpc_id      = aws_vpc.k8s_vpc.id

  ############################
  # INGRESS RULES
  ############################

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