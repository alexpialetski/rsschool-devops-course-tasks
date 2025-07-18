output "k3s_kubeconfig_secret_name" {
  value       = aws_secretsmanager_secret.k3s_kubeconfig.name
  description = "Secrets Manager secret name for k3s kubeconfig"
}

output "control_plane_instance_ids" {
  value       = aws_instance.control_plane_node[0].id
  description = "List of instance IDs for control plane nodes"
}
