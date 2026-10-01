#!/bin/bash
# ==============================================================================
# Soal 5: Entity Hostname Setup & Master DNS A Records
# Group: K-20 (Domain: k20.com & k-20.com)
# ==============================================================================
set -e

# --- Part 1: System-wide Hostname Setup (Sample node: alpha) ---
echo "alpha" > /etc/hostname
hostname alpha
grep -q "127.0.1.1 alpha" /etc/hosts || echo "127.0.1.1 alpha" >> /etc/hosts

# --- Part 2: Register All Entity A Records on DNS Master (prab) ---
cat << 'EOF' >> /etc/bind/jarkom/k20.com

; Problem 5: Entity A Records (excluding prab and tedd already in Soal 4)
rootkit IN      A       192.221.1.1
alpha   IN      A       192.221.1.2
beta    IN      A       192.221.1.3
gamma   IN      A       192.221.1.4
abbey   IN      A       192.221.2.2
delta   IN      A       192.221.3.2
epsilon IN      A       192.221.3.3
penny   IN      A       192.221.4.2
obladi  IN      A       192.221.5.4
desmond IN      A       192.221.5.5
oblada  IN      A       192.221.5.6
molly   IN      A       192.221.5.7
EOF

cat << 'EOF' >> /etc/bind/jarkom/k-20.com

; Problem 5: Entity A Records (excluding prab and tedd already in Soal 4)
rootkit IN      A       192.221.1.1
alpha   IN      A       192.221.1.2
beta    IN      A       192.221.1.3
gamma   IN      A       192.221.1.4
abbey   IN      A       192.221.2.2
delta   IN      A       192.221.3.2
epsilon IN      A       192.221.3.3
penny   IN      A       192.221.4.2
obladi  IN      A       192.221.5.4
desmond IN      A       192.221.5.5
oblada  IN      A       192.221.5.6
molly   IN      A       192.221.5.7
EOF

named-checkzone k20.com /etc/bind/jarkom/k20.com
named-checkzone k-20.com /etc/bind/jarkom/k-20.com
service bind9 reload || /etc/init.d/named reload

echo "[✓] Soal 5 setup completed successfully!"
