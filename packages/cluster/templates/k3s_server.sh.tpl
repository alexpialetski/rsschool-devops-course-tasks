#!/bin/bash

${ssm_start}
${ssh_setup}
${k3s_token}

curl -sfL https://get.k3s.io | sh -s - server --token $TOKEN --write-kubeconfig-mode 644 --disable=traefik
K3S_KUBECONFIG="/etc/rancher/k3s/k3s.yaml"

# Wait for kubeconfig to be generated
whiel [! -f "${K3S_KUBECONFIG}" ]; do
    echo "Waiting for kubeconfig to be generated..."
    sleep 5
done

aws secretsmanager put-secret-value \
    --secret-id "${secret_name}" \
    --secret-string "$(cat ${K3S_KUBECONFIG})" \
    --region ${aws_region}

if [ $? -eq 0 ]; then
    echo "✅ Kubeconfig successfully stored in Secrets Manager"
else
    echo "❌ Failed to store kubeconfig in Secrets Manager"
fi