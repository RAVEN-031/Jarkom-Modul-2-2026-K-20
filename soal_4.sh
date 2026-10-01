#!/bin/bash
# ==============================================================================
# Soal 4: BIND9 DNS Master Setup on prab (192.221.5.2)
# ==============================================================================
set -e

# 1. Install BIND9 and DNS utilities
echo "nameserver 192.168.122.1" > /etc/resolv.conf
apt-get update -y
apt-get install -y bind9 bind9utils dnsutils
ln -s /etc/init.d/named /etc/init.d/bind9 2>/dev/null || true

# 2. Configure forwarders to NAT gateway (192.168.122.1)
cat << 'EOF' > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";

    forwarders {
        192.168.122.1;
    };

    allow-query { any; };
    allow-recursion { any; };
    dnssec-validation no;
    auth-nxdomain no;
    listen-on-v6 { any; };
};
EOF

# 3. Configure master zones with notify and allow-transfer to tedd (192.221.5.3)
mkdir -p /etc/bind/jarkom
cat << 'EOF' > /etc/bind/named.conf.local
zone "k20.com" {
    type master;
    notify yes;
    also-notify { 192.221.5.3; };
    allow-transfer { 192.221.5.3; };
    file "/etc/bind/jarkom/k20.com";
};

zone "k-20.com" {
    type master;
    notify yes;
    also-notify { 192.221.5.3; };
    allow-transfer { 192.221.5.3; };
    file "/etc/bind/jarkom/k-20.com";
};
EOF

# 4. Create authoritative forward zone file for k20.com
cat << 'EOF' > /etc/bind/jarkom/k20.com
$TTL    604800
@       IN      SOA     prab.k20.com. admin.k20.com. (
                        2026100110 ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL

; Authoritative Nameservers
@       IN      NS      prab.k20.com.
@       IN      NS      tedd.k20.com.

; Apex domain points to dynamic application gateway (penny: 192.221.4.2)
@       IN      A       192.221.4.2

; Nameserver Nodes
prab    IN      A       192.221.5.2
tedd    IN      A       192.221.5.3
EOF

# 5. Create authoritative forward zone file for k-20.com
cat << 'EOF' > /etc/bind/jarkom/k-20.com
$TTL    604800
@       IN      SOA     prab.k-20.com. admin.k-20.com. (
                        2026100110 ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL

; Authoritative Nameservers
@       IN      NS      prab.k-20.com.
@       IN      NS      tedd.k-20.com.

; Apex domain points to dynamic application gateway (penny: 192.221.4.2)
@       IN      A       192.221.4.2

; Nameserver Nodes
prab    IN      A       192.221.5.2
tedd    IN      A       192.221.5.3
EOF

# 6. Validate and restart BIND9
named-checkconf
named-checkzone k20.com /etc/bind/jarkom/k20.com
named-checkzone k-20.com /etc/bind/jarkom/k-20.com
service bind9 restart || /etc/init.d/named restart

# 7. Update resolver order
cat << 'EOF' > /etc/resolv.conf
nameserver 192.221.5.2
nameserver 192.221.5.3
nameserver 192.168.122.1
EOF

echo "[✓] Soal 4 setup completed successfully on prab!"
