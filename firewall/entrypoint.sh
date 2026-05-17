#!/bin/sh
iptables -F
iptables -X
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p tcp --dport 1883 -j ACCEPT
iptables -A INPUT -j LOG --log-prefix "[FW-DROP] "
echo "[firewall] Rules applied:"
iptables -L -n -v
exec socat TCP-LISTEN:1883,fork,reuseaddr TCP:mqtt-broker:1883