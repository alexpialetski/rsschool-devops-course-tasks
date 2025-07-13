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

# Generate SSH setup script
data "template_file" "ssh_setup" {
  template = file("${path.module}/templates/ssh_private_key.sh.tpl")
  vars = {
    private_key = local.nodes_ssh_private_key
  }
}
