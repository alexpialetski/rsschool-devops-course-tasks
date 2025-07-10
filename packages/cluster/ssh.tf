# resource "tls_private_key" "rsa-4096-example" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# resource "aws_key_pair" "bastion-ssh-key" {
#   key_name   = "bastion-ssh-key"
#   public_key = data.terraform_remote_state.init_state.outputs.public_key
# }
