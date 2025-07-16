#!/bin/bash

${ssm_start}
${ssh_setup}
${k3s_token}

curl -sfL https://get.k3s.io | K3S_URL=https://${control_plane_ip}:6443 K3S_TOKEN=$TOKEN sh -