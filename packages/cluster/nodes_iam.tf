resource "aws_iam_role" "k8s_node" {
  name = "K8sNodeRole"

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

resource "aws_iam_role_policy_attachment" "secrets_manager_access" {
  role       = aws_iam_role.k8s_node.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

# TODO: use least privilege principle instead of SecretsManagerReadWrite
# resource "aws_iam_role_policy" "secrets_manager_access" {
#   name = "SecretsManagerAccess"
#   role = aws_iam_role.k8s_node.id

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = [
#           "secretsmanager:GetSecretValue",
#           "secretsmanager:DescribeSecret"
#         ],
#         Effect = "Allow",
#         Resource = aws_secretsmanager_secret.k3s_token.arn
#       }
#     ]
#   })
# }

resource "aws_iam_instance_profile" "k8s_node" {
  name = "K8sNodeInstanceProfile"
  role = aws_iam_role.k8s_node.name
}
