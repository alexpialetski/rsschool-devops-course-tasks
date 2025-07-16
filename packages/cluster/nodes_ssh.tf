################################################################################
# SSH Key Pair for EC2 Instances to communicate between each other 
################################################################################
locals {
  nodes_ssh_public_key  = tls_private_key.rsa_4096_example.public_key_openssh
  nodes_ssh_private_key = tls_private_key.rsa_4096_example.private_key_openssh
}

resource "tls_private_key" "rsa_4096_example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "cluster_ssh_key" {
  key_name   = "${local.naming_prefix}-ssh-key"
  public_key = tls_private_key.rsa_4096_example.public_key_openssh
}

# store SSH private key in AWS Secrets Manager
resource "aws_secretsmanager_secret" "nodes_ssh_private_key" {
  name        = "${local.naming_prefix}-nodes-ssh-private-key"
  description = "SSH private key for EC2 nodes in the cluster"

  # To delete secret without a scheduled time (i.e., immediately),
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "nodes_ssh_private_key" {
  secret_id     = aws_secretsmanager_secret.nodes_ssh_private_key.id
  secret_string = local.nodes_ssh_private_key
}

# Generate SSH setup script
data "template_file" "ssh_setup" {
  template = file("${path.module}/templates/ssh_private_key.sh.tpl")
  vars = {
    secret_name = aws_secretsmanager_secret.nodes_ssh_private_key.name
  }
}
