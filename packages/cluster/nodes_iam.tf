resource "aws_iam_role" "k8s_node" {
  name = "${local.naming_prefix}-k8s-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.k8s_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# TODO: use least privilege principle instead of SecretsManagerReadWrite
resource "aws_iam_role_policy_attachment" "secrets_manager_access" {
  role       = aws_iam_role.k8s_node.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_instance_profile" "k8s_node" {
  name = "K8sNodeInstanceProfile"
  role = aws_iam_role.k8s_node.name
}
