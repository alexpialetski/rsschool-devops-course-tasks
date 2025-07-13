resource "random_password" "k3s_token" {
  length  = 48
  special = false
}

resource "aws_secretsmanager_secret" "k3s_token" {
  name        = "${local.naming_prefix}-k3s-cluster-token"
  description = "K3s cluster token for node authentication"

  # To delete secret without a scheduled time (i.e., immediately),
  recovery_window_in_days = 0
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

data "template_file" "k3s_server" {
  template = file("${path.module}/templates/k3s_server.sh.tpl")
  vars = {
    ssh_setup = data.template_file.ssh_setup.rendered
    k3s_token = data.template_file.k3s_token.rendered
  }
}

data "template_file" "k3s_agent" {
  template = file("${path.module}/templates/k3s_agent.sh.tpl")
  vars = {
    ssh_setup        = data.template_file.ssh_setup.rendered
    k3s_token        = data.template_file.k3s_token.rendered
    control_plane_ip = aws_instance.control_plane_node[0].private_ip
  }
}