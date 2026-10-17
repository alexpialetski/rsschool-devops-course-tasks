locals {
  ssm_start_script = templatefile("${path.module}/templates/ssm_start.sh.tpl", {})
}

#################################################################################
# Secrets Manager for kubeconfig storage
#################################################################################

resource "aws_secretsmanager_secret" "k3s_kubeconfig" {
  name        = "${local.naming_prefix}-k3s-kubeconfig"
  description = "K3s cluster kubeconfig with certificates"

  # To delete secret without a scheduled time (i.e., immediately),
  recovery_window_in_days = 0

  tags = {
    SecretType = "kubeconfig",
  }
}

resource "aws_secretsmanager_secret_version" "k3s_kubeconfig" {
  secret_id     = aws_secretsmanager_secret.k3s_kubeconfig.id
  secret_string = "PLACEHOLDER" # This will be updated by the k3s server instance

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
  name        = "${local.naming_prefix}-k3s-cluster-token"
  description = "K3s cluster token for node authentication"

  # To delete secret without a scheduled time (i.e., immediately),
  recovery_window_in_days = 0

  tags = {
    SecretType = "token",
  }
}

resource "aws_secretsmanager_secret_version" "k3s_token" {
  secret_id     = aws_secretsmanager_secret.k3s_token.id
  secret_string = random_password.k3s_token.result
}

locals {
  k3s_token_script = templatefile("${path.module}/templates/k3s_token.sh.tpl", {
    secret_name = aws_secretsmanager_secret.k3s_token.name
  })
}

#################################################################################
# K3S Server and Agent Configuration for ec2 instances
#################################################################################

locals {
  k3s_server_script = templatefile("${path.module}/templates/k3s_server.sh.tpl", {
    ssm_start   = local.ssm_start_script
    ssh_setup   = local.ssh_setup_script
    k3s_token   = local.k3s_token_script
    secret_name = aws_secretsmanager_secret.k3s_kubeconfig.name
    aws_region  = data.aws_region.current.id
  })
}

locals {
  k3s_agent_script = templatefile("${path.module}/templates/k3s_agent.sh.tpl", {
    ssm_start        = local.ssm_start_script
    ssh_setup        = local.ssh_setup_script
    k3s_token        = local.k3s_token_script
    control_plane_ip = aws_instance.control_plane_node[0].private_ip
  })
}
