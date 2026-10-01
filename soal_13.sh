#!/bin/bash
# ==============================================================================
# Soal 13: Canonical Redirects (301 on penny, 302 on abbey)
#
# Part 1: penny (192.221.4.2) -> Apache 301 Permanent Redirect to www.k20.com
# Part 2: abbey (192.221.2.2) -> Nginx 302 Temporary Redirect to static.k20.com
# ==============================================================================
set -e

# ==============================================================================
# SECTION 1: Run on penny (192.221.4.2) - Apache 301 Redirects
# ==============================================================================
setup_penny() {
    echo "[*] Configuring Apache 301 Permanent Redirects on penny..."

    cat << 'EOF' > /etc/apache2/sites-available/000-default.conf
# 301 Permanent Redirect for raw IP and penny.k20.com -> www.k20.com
<VirtualHost *:80>
    ServerName penny.k20.com
    ServerAlias 192.221.4.2
    Redirect 301 / http://www.k20.com/
</VirtualHost>

# 301 Permanent Redirect for hyphenated domain
<VirtualHost *:80>
    ServerName penny.k-20.com
    Redirect 301 / http://www.k-20.com/
</VirtualHost>

# Canonical VirtualHost for www.k20.com
<VirtualHost *:80>
    ServerName www.k20.com
    ServerAlias www.k-20.com k20.com k-20.com
    DocumentRoot /var/www/html

    RewriteEngine On
    RewriteRule .* - [E=CLIENT_IP:%{REMOTE_ADDR}]
    RequestHeader set X-Real-IP "%{CLIENT_IP}e"
    ProxyPreserveHost On

    <Proxy "balancer://vaultcluster">
        BalancerMember "http://192.221.5.4:80"
        BalancerMember "http://192.221.5.5:80"
        ProxySet lbmethod=byrequests
    </Proxy>

    # Basic Auth on /admin
    Alias /admin/ /var/www/html/admin/
    Alias /admin /var/www/html/admin/index.html
    <Directory /var/www/html/admin>
        Options +Indexes +FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>
    <Location /admin>
        AuthType Basic
        AuthName "Restricted Syndicate Area"
        AuthUserFile /etc/apache2/.htpasswd
        Require valid-user
    </Location>

    ProxyPass /admin !
    ProxyPass / "balancer://vaultcluster/"
    ProxyPassReverse / "balancer://vaultcluster/"

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

    a2ensite 000-default.conf 2>/dev/null || true
    service apache2 restart
    echo "[✓] Apache 301 Permanent Redirects on penny configured successfully!"
}

# ==============================================================================
# SECTION 2: Run on abbey (192.221.2.2) - Nginx 302 Redirects
# ==============================================================================
setup_abbey() {
    echo "[*] Configuring Nginx 302 Temporary Redirects on abbey..."

    cat << 'EOF' > /etc/nginx/sites-available/proxy.conf
upstream core_cluster {
    server 192.221.5.6:80;
    server 192.221.5.7:80;
}

# 302 Temporary Redirect for raw IP and abbey.k20.com -> static.k20.com
server {
    listen 80;
    server_name 192.221.2.2 abbey.k20.com;
    return 302 http://static.k20.com$request_uri;
}

# 302 Temporary Redirect for hyphenated domain
server {
    listen 80;
    server_name abbey.k-20.com;
    return 302 http://static.k-20.com$request_uri;
}

# Canonical Reverse Proxy Server for static.k20.com
server {
    listen 80 default_server;
    server_name static.k20.com static.k-20.com _;

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
    echo "[✓] Nginx 302 Temporary Redirects on abbey configured successfully!"
}

# Execute based on current node
if [ "$(hostname)" = "abbey" ]; then
    setup_abbey
else
    setup_penny
fi
