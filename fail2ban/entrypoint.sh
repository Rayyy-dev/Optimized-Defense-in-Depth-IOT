#!/bin/sh
echo "[fail2ban] Cleaning stale sockets..."
mkdir -p /var/run/fail2ban
rm -f /var/run/fail2ban/fail2ban.sock /var/run/fail2ban/fail2ban.pid
echo "[fail2ban] Starting service..."
fail2ban-server -f -v