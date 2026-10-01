#!/bin/bash
# ==============================================================================
# Soal 2: NAT Configuration on Router rootkit
# ==============================================================================
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sysctl -w net.ipv4.ip_forward=1
echo "[✓] NAT Gateway on rootkit configured."
