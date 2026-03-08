#!/bin/bash

# Enable IP forwarding (required for exit node)
modprobe xt_mark 2>/dev/null || true

sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Start Tailscale daemon
mkdir -p /data/tailscale
/app/tailscaled --state=/data/tailscaled.state --statedir=/data/tailscale --socket=/var/run/tailscale/tailscaled.sock &

# Connect to Tailnet with exit node and SSH
/app/tailscale up --auth-key=${TAILSCALE_AUTHKEY} --hostname=${TAILSCALE_HOSTNAME:-mtproxy} --advertise-exit-node --ssh

# Run the original MTProxy entrypoint
exec /bin/bash /run.sh
