#!/bin/bash
# ==============================================================================
# Soal 7: Round-Robin Pools (Vault & Core) and CNAME Aliases on prab (192.221.5.2)
# ==============================================================================
set -e

# 1. Append Round-Robin A records and CNAMEs to k20.com
cat << 'EOF' >> /etc/bind/jarkom/k20.com

; Problem 7: Round-Robin A Records
vault   IN      A       192.221.5.4
vault   IN      A       192.221.5.5
core    IN      A       192.221.5.6
core    IN      A       192.221.5.7

; Problem 7: CNAME Records
www     IN      CNAME   penny.k20.com.
static  IN      CNAME   abbey.k20.com.
EOF

# 2. Append Round-Robin A records and CNAMEs to k-20.com
cat << 'EOF' >> /etc/bind/jarkom/k-20.com

; Problem 7: Round-Robin A Records
vault   IN      A       192.221.5.4
vault   IN      A       192.221.5.5
core    IN      A       192.221.5.6
core    IN      A       192.221.5.7

; Problem 7: CNAME Records
www     IN      CNAME   penny.k-20.com.
static  IN      CNAME   abbey.k-20.com.
EOF

# 3. Validate zones and reload BIND9
named-checkzone k20.com /etc/bind/jarkom/k20.com
named-checkzone k-20.com /etc/bind/jarkom/k-20.com
service bind9 reload || /etc/init.d/named reload

# 4. Verify resolution
echo "=== Verifying Problem 7 DNS Records ==="
echo "[*] vault.k20.com (obladi & desmond):"
dig +short vault.k20.com

echo "[*] core.k20.com (oblada & molly):"
dig +short core.k20.com

echo "[*] www.k20.com (CNAME -> penny):"
dig +short www.k20.com

echo "[*] static.k20.com (CNAME -> abbey):"
dig +short static.k20.com

echo "[✓] Soal 7 setup completed on prab!"
