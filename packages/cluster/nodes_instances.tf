################################################################################
# Control Plane and Agent Nodes
################################################################################

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

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
  user_data     = data.template_file.k3s_server.rendered
  instance_type = var.control_plane_config.instanceType

  launch_template {
    id      = aws_launch_template.k8s_node.id
    version = "$Latest"
  }

  tags = {
    Name = "${local.naming_prefix}-control-plane-${count.index + 1}"
  }
}

resource "aws_instance" "agent_node" {
  count = var.agent_nodes_config.nodesNumber

  subnet_id     = aws_subnet.private[count.index % length(aws_subnet.private)].id
  user_data     = data.template_file.k3s_agent.rendered
  instance_type = var.agent_nodes_config.instanceType

  launch_template {
    id      = aws_launch_template.k8s_node.id
    version = "$Latest"
  }

  tags = {
    Name = "${local.naming_prefix}-agent-${count.index + 1}"
  }
}
