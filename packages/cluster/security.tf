# # Security group for Kubernetes control plane nodes
# resource "aws_security_group" "control_plane" {
#   name        = "${local.naming_prefix}-control-plane-sg"
#   description = "Security group for K8s control plane nodes"
#   vpc_id      = aws_vpc.k8s_vpc.id

#   # Allow all traffic between control plane nodes
#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     self        = true
#     description = "Allow all traffic between control plane nodes"
#   }

#   # Allow all outbound traffic
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "Allow all outbound traffic"
#   }

#   tags = {
#     Name        = "${local.naming_prefix}-control-plane-sg"
#     Environment = var.environment
#   }
# }

# # Security group for Kubernetes worker nodes
# resource "aws_security_group" "workers" {
#   name        = "${local.naming_prefix}-workers-sg"
#   description = "Security group for K8s worker nodes"
#   vpc_id      = aws_vpc.k8s_vpc.id

#   # Allow all traffic between worker nodes
#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     self        = true
#     description = "Allow all traffic between worker nodes"
#   }

#   # Allow all traffic from control plane nodes
#   ingress {
#     from_port       = 0
#     to_port         = 0
#     protocol        = "-1"
#     security_groups = [aws_security_group.control_plane.id]
#     description     = "Allow all traffic from control plane nodes"
#   }

#   # Allow all outbound traffic
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "Allow all outbound traffic"
#   }

#   tags = {
#     Name        = "${local.naming_prefix}-workers-sg"
#     Environment = var.environment
#   }
# }
