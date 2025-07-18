data "template_file" "ssm_start" {
  template = file("${path.module}/templates/ssm_start.sh.tpl")
}

#################################################################################
# Secrets Manager for kubeconfig storage
#################################################################################

resource "aws_secretsmanager_secret" "k3s_kubeconfig" {
  description = "K3s cluster kubeconfig with certificates"

  # To delete secret without a scheduled time (i.e., immediately),
  recovery_window_in_days = 0

  tags = {
    Name       = "${local.naming_prefix}-k3s-kubeconfig",
    SecretType = "kubeconfig",
  }
}

resource "aws_secretsmanager_secret_version" "k3s_kubeconfig" {
  secret_id     = aws_secretsmanager_secret.k3s_kubeconfig.id
  secret_string = "" # This will be updated by the k3s server instance

  lifecycle {
    ignore_changes = [secret_string]
  }
}

#################################################################################
# K3S token management
#################################################################################

resource "random_password" "k3s_token" {
  length  = 48
  special = false
}

resource "aws_secretsmanager_secret" "k3s_token" {
  description = "K3s cluster token for node authentication"

  # To delete secret without a scheduled time (i.e., immediately),
  recovery_window_in_days = 0

  tags = {
    Name       = "${local.naming_prefix}-k3s-cluster-token",
    SecretType = "token",
  }
}

resource "aws_secretsmanager_secret_version" "k3s_token" {
  secret_id     = aws_secretsmanager_secret.k3s_token.id
  secret_string = random_password.k3s_token.result
}

data "template_file" "k3s_token" {
  template = file("${path.module}/templates/k3s_token.sh.tpl")
  vars = {
    secret_name = aws_secretsmanager_secret.k3s_token.name
  }
}

#################################################################################
# K3S Server and Agent Configuration for ec2 instances
#################################################################################

data "template_file" "k3s_server" {
  template = file("${path.module}/templates/k3s_server.sh.tpl")
  vars = {
    ssm_start   = data.template_file.ssm_start.rendered
    ssh_setup   = data.template_file.ssh_setup.rendered
    k3s_token   = data.template_file.k3s_token.rendered
    secret_name = aws_secretsmanager_secret.k3s_kubeconfig.name
    aws_region  = data.aws_region.current.id
  }
}

data "template_file" "k3s_agent" {
  template = file("${path.module}/templates/k3s_agent.sh.tpl")
  vars = {
    ssm_start        = data.template_file.ssm_start.rendered
    ssh_setup        = data.template_file.ssh_setup.rendered
    k3s_token        = data.template_file.k3s_token.rendered
    control_plane_ip = aws_instance.control_plane_node[0].private_ip
  }
}
