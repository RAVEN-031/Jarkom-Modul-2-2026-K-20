#!/bin/bash
# ==============================================================================
# Soal 12: Basic Authentication Protection for /admin on penny (192.221.4.2)
# Credentials:
#   username: prabs
#   password: pakar_pinter_jadi_gob***
# ==============================================================================
set -e

# 1. Install apache2-utils and enable auth modules
apt-get update -y
apt-get install -y apache2-utils
a2enmod auth_basic authn_file authz_user authz_core 2>/dev/null || true

# 2. Create restricted document directory
mkdir -p /var/www/html/admin
cat << 'EOF' > /var/www/html/admin/index.html
<!DOCTYPE html>
<html>
<head><title>Dokumen Rahasia Sindikat</title></head>
<body>
  <h1>Dokumen Rahasia Sindikat - Area Terbatas /admin</h1>
  <p>Autentikasi Berhasil. Selamat datang, prabs.</p>
</body>
</html>
EOF
chown -R www-data:www-data /var/www/html/admin

# 3. Create .htpasswd file
htpasswd -bc /etc/apache2/.htpasswd prabs "pakar_pinter_jadi_gob***"
chmod 640 /etc/apache2/.htpasswd
chown root:www-data /etc/apache2/.htpasswd

# 4. Update Apache VirtualHost configuration
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

    # Problem 12: Basic Auth protection on /admin
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

    # Exclude /admin from reverse proxy
    ProxyPass /admin !
    ProxyPass / "balancer://vaultcluster/"
    ProxyPassReverse / "balancer://vaultcluster/"

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# 5. Enable site and restart Apache2
a2ensite 000-default.conf 2>/dev/null || true
service apache2 restart

echo "[✓] Soal 12 setup completed on penny!"
