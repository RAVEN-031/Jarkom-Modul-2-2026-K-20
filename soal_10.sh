#!/bin/bash
# ==============================================================================
# Soal 10: Dynamic Web Server (Nginx + PHP-FPM) with /profil Rewrite on oblada (192.221.5.6)
# (Note: molly (192.221.5.7) has the identical configuration)
# ==============================================================================
set -e

# 1. Install Nginx and PHP-FPM
apt-get update -y
apt-get install -y nginx php-fpm php-cli

# Detect and start PHP-FPM service
PHP_SERVICE=$(ls -1 /etc/init.d/php*-fpm 2>/dev/null | head -n 1 | xargs -n1 basename || true)
if [ -n "$PHP_SERVICE" ]; then
    service "$PHP_SERVICE" start 2>/dev/null || /etc/init.d/"$PHP_SERVICE" start 2>/dev/null || true
fi
sleep 1
PHP_SOCK=$(ls -1 /run/php/php*-fpm.sock 2>/dev/null | head -n 1 || true)
if [ -z "$PHP_SOCK" ]; then
    PHP_SOCK="/run/php/php8.4-fpm.sock"
fi

# 2. Create web root /var/www/core with index.php and profil.php
mkdir -p /var/www/core

cat << 'EOF' > /var/www/core/index.php
<!DOCTYPE html>
<html>
<head><title>Core Dynamic Application - oblada</title></head>
<body>
  <h1>Core Dynamic Application (Node: oblada - 192.221.5.6)</h1>
  <p>Selamat datang di Repositori Memori Aplikasi Dinamis.</p>
  <p><a href="/profil">Kunjungi Halaman Profil</a></p>
  <hr>
  <p>Visitor IP detected: <?php echo $_SERVER['HTTP_X_REAL_IP'] ?? $_SERVER['REMOTE_ADDR']; ?></p>
</body>
</html>
EOF

cat << 'EOF' > /var/www/core/profil.php
<!DOCTYPE html>
<html>
<head><title>Profil Pengguna - oblada</title></head>
<body>
  <h1>Halaman Profil Entitas</h1>
  <p>ID: Oblada-Core</p>
  <p>Peran: Dynamic Core Engine</p>
  <p>Node IP: 192.221.5.6</p>
  <hr>
  <p><a href="/">Kembali ke Beranda</a></p>
</body>
</html>
EOF

chown -R www-data:www-data /var/www/core

# 3. Configure Nginx VirtualHost with FastCGI and clean /profil rewrite
cat << EOF > /etc/nginx/sites-available/core.conf
server {
    listen 80;
    server_name oblada.k20.com oblada.k-20.com core.k20.com core.k-20.com static.k20.com static.k-20.com www.k20.com www.k-20.com _;
    root /var/www/core;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    # Problem 10: Clean URL rewrite for /profil -> /profil.php
    location /profil {
        rewrite ^/profil/?$ /profil.php last;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:$PHP_SOCK;
        fastcgi_param HTTP_X_REAL_IP \$http_x_real_ip;
    }
}
EOF

ln -sf /etc/nginx/sites-available/core.conf /etc/nginx/sites-enabled/core.conf
rm -f /etc/nginx/sites-enabled/default

# 4. Test and restart services
nginx -t
if [ -n "$PHP_SERVICE" ]; then
    service "$PHP_SERVICE" restart 2>/dev/null || true
fi
service nginx restart

echo "[✓] Soal 10 setup completed on oblada!"
