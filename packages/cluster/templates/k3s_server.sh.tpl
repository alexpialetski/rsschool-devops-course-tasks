#!/bin/bash

${ssh_setup}
${k3s_token}

curl -sfL https://get.k3s.io | sh -s - server --token $TOKEN --write-kubeconfig-mode 644 --disable=traefik