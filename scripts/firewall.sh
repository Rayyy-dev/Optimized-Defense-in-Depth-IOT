#!/bin/sh
# Layer 2 Firewall — applies Least Functionality (E.14) and Domain Separation (E.12)
# Only allows inbound MQTT (1883) from external network
# Blocks all other traffic by default (deny-by-default)

echo "[firewall] Applying nftables-style iptables rules..."

# Flush existing rules
iptables -F
iptables -X

# Default DROP for inbound traffic from external network
iptables -P INPUT DROP
iptables -P FORWARD DROP

# Allow established connections back
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow loopback (needed for socat)
iptables -A INPUT -i lo -j ACCEPT

# Allow MQTT (1883) from anywhere
iptables -A INPUT -p tcp --dport 1883 -j ACCEPT

# Log dropped packets (so we can show evidence later)
iptables -A INPUT -j LOG --log-prefix "[FW-DROP] " --log-level 4

echo "[firewall] Rules applied. Current rules:"
iptables -L -n -v