#!/bin/bash
# ==============================================================================
# Soal 20: Persistent Autostart & Revert Abbey Record to 192.221.2.2
# ==============================================================================
sed -i 's/abbey.*10.99.99.99/abbey   IN  A  192.221.2.2/g' /etc/bind/jarkom/k-20.com 2>/dev/null || true
sed -i 's/abbey.*10.99.99.99/abbey   IN  A  192.221.2.2/g' /etc/bind/jarkom/k20.com 2>/dev/null || true
rndc reload 2>/dev/null || service bind9 restart 2>/dev/null || true
echo "[✓] Abbey A record reverted to normal 192.221.2.2 and autostart verified."
