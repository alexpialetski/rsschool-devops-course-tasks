################################################################################
# Control Plane and Agent Nodes
################################################################################

resource "aws_launch_template" "k8s_node" {
  name_prefix            = "${local.naming_prefix}-node-"
  image_id               = data.aws_ami.amazon_linux_2023.id
  key_name               = aws_key_pair.cluster_ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.node_security_group.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.k8s_node.name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "control_plane_node" {
  count = var.control_plane_config.nodesNumber

  subnet_id     = aws_subnet.private[count.index % length(aws_subnet.private)].id
  instance_type = var.control_plane_config.instanceType

  user_data                   = data.template_file.k3s_server.rendered
  user_data_replace_on_change = true

  launch_template {
    id      = aws_launch_template.k8s_node.id
    version = "$Latest"
  }

  # needed for installing k3s from internet 
  depends_on = [aws_instance.nat_instance]

  tags = {
    Name = "${local.naming_prefix}-control-plane-${count.index + 1}"
  }
}

resource "aws_instance" "agent_node" {
  count = var.agent_nodes_config.nodesNumber

  subnet_id     = aws_subnet.private[count.index % length(aws_subnet.private)].id
  instance_type = var.agent_nodes_config.instanceType

  user_data                   = data.template_file.k3s_agent.rendered
  user_data_replace_on_change = true

  launch_template {
    id      = aws_launch_template.k8s_node.id
    version = "$Latest"
  }

  # needed for installing k3s from internet 
  depends_on = [aws_instance.nat_instance]

  tags = {
    Name = "${local.naming_prefix}-agent-${count.index + 1}"
  }
}
