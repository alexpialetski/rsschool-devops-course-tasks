output "k3s_kubeconfig_secret_name" {
  value       = aws_secretsmanager_secret.k3s_kubeconfig.name
  description = "Secrets Manager secret name for k3s kubeconfig"
}

output "control_plane_instance_ids" {
  value       = aws_instance.control_plane_node[0].id
  description = "List of instance IDs for control plane nodes"
}

output "temp_kubeconfig_value" {
  value       = local.temp_kubeconfig_value
  description = "Temporary kubeconfig value placeholder, will be updated by the k3s server instance"
}
