#!/bin/bash
# ==============================================================================
# Soal 8: Authoritative Reverse PTR Zones Setup on prab (192.221.5.2)
# Subnets: 2 (abbey), 4 (penny), 5 (vault & core nodes)
# ==============================================================================
set -e

# 1. Append reverse zones declaration to /etc/bind/named.conf.local
cat << 'EOF' >> /etc/bind/named.conf.local

// Problem 8: Reverse PTR Zones
zone "2.221.192.in-addr.arpa" {
    type master;
    notify yes;
    also-notify { 192.221.5.3; };
    allow-transfer { 192.221.5.3; };
    file "/etc/bind/jarkom/2.221.192.in-addr.arpa";
};

zone "4.221.192.in-addr.arpa" {
    type master;
    notify yes;
    also-notify { 192.221.5.3; };
    allow-transfer { 192.221.5.3; };
    file "/etc/bind/jarkom/4.221.192.in-addr.arpa";
};

zone "5.221.192.in-addr.arpa" {
    type master;
    notify yes;
    also-notify { 192.221.5.3; };
    allow-transfer { 192.221.5.3; };
    file "/etc/bind/jarkom/5.221.192.in-addr.arpa";
};
EOF

# 2. Reverse Zone File for Subnet 2 (abbey: 192.221.2.2)
cat << 'EOF' > /etc/bind/jarkom/2.221.192.in-addr.arpa
$TTL    604800
@       IN      SOA     prab.k20.com. admin.k20.com. (
                        2026100110 ; Serial
                        604800
                        86400
                        2419200
                        604800 )
@       IN      NS      prab.k20.com.
@       IN      NS      tedd.k20.com.

2       IN      PTR     abbey.k20.com.
EOF

# 3. Reverse Zone File for Subnet 4 (penny: 192.221.4.2)
cat << 'EOF' > /etc/bind/jarkom/4.221.192.in-addr.arpa
$TTL    604800
@       IN      SOA     prab.k20.com. admin.k20.com. (
                        2026100110 ; Serial
                        604800
                        86400
                        2419200
                        604800 )
@       IN      NS      prab.k20.com.
@       IN      NS      tedd.k20.com.

2       IN      PTR     penny.k20.com.
EOF

# 4. Reverse Zone File for Subnet 5 (prab, tedd, vault, core)
cat << 'EOF' > /etc/bind/jarkom/5.221.192.in-addr.arpa
$TTL    604800
@       IN      SOA     prab.k20.com. admin.k20.com. (
                        2026100110 ; Serial
                        604800
                        86400
                        2419200
                        604800 )
@       IN      NS      prab.k20.com.
@       IN      NS      tedd.k20.com.

2       IN      PTR     prab.k20.com.
3       IN      PTR     tedd.k20.com.
4       IN      PTR     obladi.k20.com.
5       IN      PTR     desmond.k20.com.
6       IN      PTR     oblada.k20.com.
7       IN      PTR     molly.k20.com.
EOF

# 5. Check syntax and reload BIND9
named-checkzone 2.221.192.in-addr.arpa /etc/bind/jarkom/2.221.192.in-addr.arpa
named-checkzone 4.221.192.in-addr.arpa /etc/bind/jarkom/4.221.192.in-addr.arpa
named-checkzone 5.221.192.in-addr.arpa /etc/bind/jarkom/5.221.192.in-addr.arpa
service bind9 reload || /etc/init.d/named reload

# 6. Verify reverse lookups
echo "=== Verifying PTR Records ==="
host -t PTR 192.221.2.2
host -t PTR 192.221.4.2
host -t PTR 192.221.5.4
host -t PTR 192.221.5.5
host -t PTR 192.221.5.6
host -t PTR 192.221.5.7

echo "[✓] Soal 8 reverse zones completed on prab!"
