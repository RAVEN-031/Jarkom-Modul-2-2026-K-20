#!/bin/bash
# ==============================================================================
# Soal 6: BIND9 DNS Slave Zone Transfer & Serial Sync Setup on tedd (192.221.5.3)
# ==============================================================================
set -e

# 1. Install BIND9 on slave
echo "nameserver 192.168.122.1" > /etc/resolv.conf
apt-get update -y
apt-get install -y bind9 bind9utils dnsutils
ln -s /etc/init.d/named /etc/init.d/bind9 2>/dev/null || true

# 2. Configure /etc/bind/named.conf.options
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

# 3. Ensure slave storage directory with proper permissions
mkdir -p /var/lib/bind
chown -R bind:bind /var/lib/bind 2>/dev/null || true
chmod 775 /var/lib/bind 2>/dev/null || true

# 4. Configure slave zones pulling from Master (prab - 192.221.5.2)
cat << 'EOF' > /etc/bind/named.conf.local
zone "k20.com" {
    type slave;
    masters { 192.221.5.2; };
    file "/var/lib/bind/k20.com";
};

zone "k-20.com" {
    type slave;
    masters { 192.221.5.2; };
    file "/var/lib/bind/k-20.com";
};
EOF

# 5. Restart BIND9 on tedd
named-checkconf
rm -f /var/lib/bind/* 2>/dev/null || true
service bind9 restart || /etc/init.d/named restart

# 6. Verify Zone Transfer & Compare Serials
echo "[*] Checking SOA Serial from Master (prab - 192.221.5.2)..."
dig @192.221.5.2 k20.com SOA +short

echo "[*] Checking SOA Serial from Slave (tedd - 192.221.5.3)..."
dig @192.221.5.3 k20.com SOA +short

echo "[*] Verifying AXFR transfer..."
dig @192.221.5.2 k20.com AXFR +noall +answer

echo "[✓] Soal 6 setup and verification completed on tedd!"
