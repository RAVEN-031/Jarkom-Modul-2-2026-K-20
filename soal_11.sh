#!/bin/bash
# ==============================================================================
# Soal 11: Reverse Proxy & Load Balancing with Host and X-Real-IP Forwarding
#
# Part 1: penny (192.221.4.2) -> Apache Load Balancer to Vault (obladi & desmond)
# Part 2: abbey (192.221.2.2) -> Nginx Load Balancer to Core (oblada & molly)
# ==============================================================================
set -e

# ==============================================================================
# SECTION 1: Run on penny (192.221.4.2) - Apache Reverse Proxy
# ==============================================================================
setup_penny() {
    echo "[*] Setting up Apache Reverse Proxy on penny..."
    apt-get update -y
    apt-get install -y apache2

    a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests rewrite headers
    a2dismod mpm_event 2>/dev/null || true
    a2enmod mpm_prefork 2>/dev/null || true

    cat << 'EOF' > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    ServerName penny.k20.com
    ServerAlias penny.k-20.com www.k20.com www.k-20.com k20.com k-20.com 192.221.4.2

    # Forward client IP via X-Real-IP and preserve Host header
    RewriteEngine On
    RewriteRule .* - [E=CLIENT_IP:%{REMOTE_ADDR}]
    RequestHeader set X-Real-IP "%{CLIENT_IP}e"
    ProxyPreserveHost On

    <Proxy "balancer://vaultcluster">
        BalancerMember "http://192.221.5.4:80"
        BalancerMember "http://192.221.5.5:80"
        ProxySet lbmethod=byrequests
    </Proxy>

    ProxyPass / "balancer://vaultcluster/"
    ProxyPassReverse / "balancer://vaultcluster/"

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

    a2ensite 000-default.conf 2>/dev/null || true
    service apache2 restart
    echo "[✓] Apache Reverse Proxy on penny configured successfully!"
}

# ==============================================================================
# SECTION 2: Run on abbey (192.221.2.2) - Nginx Reverse Proxy
# ==============================================================================
setup_abbey() {
    echo "[*] Setting up Nginx Reverse Proxy on abbey..."
    apt-get update -y
    apt-get install -y nginx

    cat << 'EOF' > /etc/nginx/sites-available/proxy.conf
upstream core_cluster {
    server 192.221.5.6:80;
    server 192.221.5.7:80;
}

server {
    listen 80 default_server;
    server_name abbey.k20.com abbey.k-20.com static.k20.com static.k-20.com 192.221.2.2 _;

    # Forward Host, X-Real-IP, and X-Forwarded-For to core cluster
    location / {
        proxy_pass http://core_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

    ln -sf /etc/nginx/sites-available/proxy.conf /etc/nginx/sites-enabled/proxy.conf
    rm -f /etc/nginx/sites-enabled/default

    nginx -t
    service nginx restart
    echo "[✓] Nginx Reverse Proxy on abbey configured successfully!"
}

# Execute based on current node
if [ "$(hostname)" = "abbey" ]; then
    setup_abbey
else
    setup_penny
fi
