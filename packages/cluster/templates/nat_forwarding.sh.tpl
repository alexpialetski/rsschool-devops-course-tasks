#!/bin/bash

# Enable IP forwarding for routing
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

# Set up NAT to allow private instances to access the internet through Bastion
iptables -t nat -A POSTROUTING -o ens5 -s 0.0.0.0/0 -j MASQUERADE

# reestablish connections
systemctl restart amazon-ssm-agent.service