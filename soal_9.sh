#!/bin/bash
# ==============================================================================
# Soal 9: Static Web Server with Apache & /arsip/ Autoindex on obladi (192.221.5.4)
# (Note: desmond (192.221.5.5) has the identical configuration)
# ==============================================================================
set -e

# 1. Install Apache2
apt-get update -y
apt-get install -y apache2

# 2. Create /var/www/html/arsip directory and files
mkdir -p /var/www/html/arsip

cat << 'EOF' > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head><title>Vault Static Repository - obladi</title></head>
<body>
  <h1>Vault Static Repository (obladi - 192.221.5.4)</h1>
  <p><a href="/arsip/">Browse /arsip/ directory listing</a></p>
</body>
</html>
EOF

echo "Arsip Rahasia The Mesh - Vault Obladi Node" > /var/www/html/arsip/arsip_obladi.txt
echo "Laporan Eksekusi Vault 2026" > /var/www/html/arsip/laporan.txt

# 3. Configure Apache VirtualHost with autoindex
cat << 'EOF' > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    ServerName obladi.k20.com
    ServerAlias obladi.k-20.com vault.k20.com vault.k-20.com www.k20.com *
    DocumentRoot /var/www/html

    <Directory /var/www/html/arsip>
        Options +Indexes +FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# 4. Enable modules and restart Apache2
a2enmod autoindex rewrite 2>/dev/null || true
a2ensite 000-default.conf 2>/dev/null || true
service apache2 restart

echo "[✓] Soal 9 setup completed on obladi!"
