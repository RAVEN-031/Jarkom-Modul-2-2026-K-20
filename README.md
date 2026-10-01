# Laporan Resmi Praktikum Modul-2

**Kelompok: K-20**  
- **Domain Utama:** `k20.com`  
- **Domain Tanda-Hubung:** `k-20.com`  
- **Prefix Subnet:** `192.221.X.X`  

---

## Soal 4

Penjaga Direktori mulai menuliskan hukum The Mesh. Pada node `prab`, bangun zona `k20.com` sebagai authoritative dengan SOA yang menunjuk ke `prab.k20.com`, serta tambahkan catatan NS untuk `prab` dan `tedd`. Record A dibuat untuk `prab` (`192.221.5.2`) dan `tedd` (`192.221.5.3`), serta record apex `k20.com` yang mengarah ke gerbang aplikasi dinamis (`penny` - `192.221.4.2`). Aktifkan fitur notify dan allow-transfer ke `tedd`, lalu set forwarders ke `192.168.122.1`. Di node `tedd`, tarik zona `k20.com` dari master sebagai slave. Perbarui pula urutan resolver pada seluruh entitas non-router menjadi: IP `prab`, IP `tedd`, lalu `192.168.122.1`. Konfigurasi yang sama diterapkan untuk domain tanda-hubung `k-20.com`.

### 1. Konfigurasi Master DNS (prab)

File `/etc/bind/named.conf.options`:
```named
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
```

File `/etc/bind/named.conf.local`:
```named
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
```

File Zona `/etc/bind/jarkom/k20.com`:
```dns
$TTL    604800
@       IN      SOA     prab.k20.com. admin.k20.com. (
                        2026100110 ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL

; Nameservers
@       IN      NS      prab.k20.com.
@       IN      NS      tedd.k20.com.

; Apex domain points to penny (192.221.4.2)
@       IN      A       192.221.4.2

; Nameserver Nodes
prab    IN      A       192.221.5.2
tedd    IN      A       192.221.5.3
```

*(Konfigurasi zona `/etc/bind/jarkom/k-20.com` identik untuk domain `k-20.com`)*

### 2. Konfigurasi Slave DNS (tedd)

File `/etc/bind/named.conf.local`:
```named
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
```

### 3. Konfigurasi Resolver pada Klien

File `/etc/resolv.conf`:
```text
nameserver 192.221.5.2
nameserver 192.221.5.3
nameserver 192.168.122.1
```

### 4. Hasil Pengujian

Query apex domain `k20.com` ke Master (`prab`):
```text
root@gamma:~# dig @192.221.5.2 k20.com +short
192.221.4.2
```

Query apex domain `k20.com` ke Slave (`tedd`):
```text
root@gamma:~# dig @192.221.5.3 k20.com +short
192.221.4.2
```

<img width="850" height="250" alt="Bukti Pengujian Soal 4" src="https://github.com/user-attachments/assets/placeholder-soal-4" />

---

## Soal 5

Seluruh Entitas (14 node) dinamai sesuai glosarium secara system-wide pada `/etc/hostname` dan `/etc/hosts`: `rootkit`, `alpha`, `beta`, `gamma`, `delta`, `epsilon`, `prab`, `tedd`, `abbey`, `penny`, `obladi`, `desmond`, `oblada`, `molly`. Setiap domain node didaftarkan pada DNS Master (`prab`) dengan record A yang sesuai (kecuali `prab` dan `tedd` yang sudah didaftarkan pada Soal 4).

### 1. Konfigurasi Hostname Node (Contoh pada Alpha)

File `/etc/hostname`:
```text
alpha
```

File `/etc/hosts`:
```text
127.0.0.1 localhost
127.0.1.1 alpha
```

Perintah aktivasi:
```bash
hostname -F /etc/hostname
```

### 2. Penambahan Record A pada DNS Master (prab)

Ditambahkan ke `/etc/bind/jarkom/k20.com` dan `/etc/bind/jarkom/k-20.com`:
```dns
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
```

### 3. Hasil Pengujian

Pengujian pengenalan hostname system-wide dan resolusi DNS:
```text
root@alpha:~# hostname
alpha

root@gamma:~# ping -c 2 alpha.k20.com
PING alpha.k20.com (192.221.1.2) 56(84) bytes of data.
64 bytes from alpha (192.221.1.2): icmp_seq=1 ttl=64 time=0.082 ms
64 bytes from alpha (192.221.1.2): icmp_seq=2 ttl=64 time=0.071 ms

--- alpha.k20.com ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1024ms
```

<img width="850" height="250" alt="Bukti Pengujian Soal 5" src="https://github.com/user-attachments/assets/placeholder-soal-5" />

---

## Soal 6

Memastikan mekanisme Zone Transfer (AXFR) dari `prab` ke `tedd` berjalan dengan baik dan nilai serial SOA pada kedua server DNS sama persis. Akses zone transfer dibatasi hanya untuk IP `tedd` (`192.221.5.3`), dan klien tidak berhak akan ditolak.

### 1. Konfigurasi Zone Transfer

Pada `prab` (`/etc/bind/named.conf.local`):
```named
allow-transfer { 192.221.5.3; };
also-notify { 192.221.5.3; };
notify yes;
```

Pada `tedd` (`/etc/bind/named.conf.local`):
```named
type slave;
masters { 192.221.5.2; };
file "/var/lib/bind/k20.com";
```

### 2. Hasil Pengujian

Perbandingan Serial SOA antara Master dan Slave:
```text
root@tedd:~# dig @192.221.5.2 k20.com SOA +short
prab.k20.com. admin.k20.com. 2026100110 604800 86400 2419200 604800

root@tedd:~# dig @192.221.5.3 k20.com SOA +short
prab.k20.com. admin.k20.com. 2026100110 604800 86400 2419200 604800
```
Serial SOA pada kedua DNS server sama (`2026100110`).

Verifikasi File Zona Tersimpan pada `tedd`:
```text
root@tedd:~# ls -la /var/lib/bind/
total 16
drwxrwxr-x 2 bind bind 4096 Oct  1 20:03 .
drwxr-xr-x 8 root root 4096 Oct  1 20:00 ..
-rw-r--r-- 1 bind bind  748 Oct  1 20:03 k-20.com
-rw-r--r-- 1 bind bind  748 Oct  1 20:03 k20.com
```

Pengujian Pembatasan Hak Transfer dari Klien Tidak Sah (gamma):
```text
root@gamma:~# dig @192.221.5.2 k20.com AXFR
; <<>> DiG 9.20.29 <<>> @192.221.5.2 k20.com AXFR
; (1 server found)
;; global options: +cmd
; Transfer failed.
```

<img width="850" height="250" alt="Bukti Pengujian Soal 6" src="https://github.com/user-attachments/assets/placeholder-soal-6" />

---

## Soal 7

Konfigurasi DNS Round-Robin A record untuk area vault (`vault.k20.com` mengarah ke `obladi` dan `desmond`) dan area core (`core.k20.com` mengarah ke `oblada` dan `molly`), serta penambahan CNAME kanonikal:
- `www.k20.com` $\rightarrow$ `penny.k20.com.`
- `static.k20.com` $\rightarrow$ `abbey.k20.com.`

Pengujian diverifikasi dari dua klien berbeda (`gamma` pada Subnet 1 dan `delta` pada Subnet 3).

### 1. Konfigurasi Record pada Zona DNS (prab)

Ditambahkan ke `/etc/bind/jarkom/k20.com` dan `/etc/bind/jarkom/k-20.com`:
```dns
; Problem 7: Round-Robin A Records
vault   IN      A       192.221.5.4
vault   IN      A       192.221.5.5
core    IN      A       192.221.5.6
core    IN      A       192.221.5.7

; Problem 7: CNAME Records
www     IN      CNAME   penny.k20.com.
static  IN      CNAME   abbey.k20.com.
```

### 2. Hasil Pengujian dari Klien gamma (Subnet 1)

```text
root@gamma:~# dig vault.k20.com +short
192.221.5.4
192.221.5.5

root@gamma:~# dig core.k20.com +short
192.221.5.6
192.221.5.7

root@gamma:~# dig www.k20.com +short
penny.k20.com.
192.221.4.2

root@gamma:~# dig static.k20.com +short
abbey.k20.com.
192.221.2.2
```

### 3. Hasil Pengujian dari Klien delta (Subnet 3)

```text
root@delta:~# dig vault.k20.com +short
192.221.5.5
192.221.5.4

root@delta:~# dig core.k20.com +short
192.221.5.7
192.221.5.6

root@delta:~# dig www.k20.com +short
penny.k20.com.
192.221.4.2

root@delta:~# dig static.k20.com +short
abbey.k20.com.
192.221.2.2
```

<img width="850" height="250" alt="Bukti Pengujian Soal 7" src="https://github.com/user-attachments/assets/placeholder-soal-7" />

---

## Soal 8

Deklarasi zona reverse (PTR) untuk segmen jaringan gateway dan server:
- Subnet 2: `2.221.192.in-addr.arpa` (`abbey`)
- Subnet 4: `4.221.192.in-addr.arpa` (`penny`)
- Subnet 5: `5.221.192.in-addr.arpa` (`prab`, `tedd`, `obladi`, `desmond`, `oblada`, `molly`)

Dikonfigurasi sebagai master di `prab` dan ditarik sebagai slave di `tedd`.

### 1. Konfigurasi Reverse Zones pada prab (Master)

File `/etc/bind/named.conf.local`:
```named
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
```

File `/etc/bind/jarkom/2.221.192.in-addr.arpa`:
```dns
$TTL    604800
@       IN      SOA     prab.k20.com. admin.k20.com. (
                        2026100110 604800 86400 2419200 604800 )
@       IN      NS      prab.k20.com.
@       IN      NS      tedd.k20.com.

2       IN      PTR     abbey.k20.com.
```

File `/etc/bind/jarkom/4.221.192.in-addr.arpa`:
```dns
$TTL    604800
@       IN      SOA     prab.k20.com. admin.k20.com. (
                        2026100110 604800 86400 2419200 604800 )
@       IN      NS      prab.k20.com.
@       IN      NS      tedd.k20.com.

2       IN      PTR     penny.k20.com.
```

File `/etc/bind/jarkom/5.221.192.in-addr.arpa`:
```dns
$TTL    604800
@       IN      SOA     prab.k20.com. admin.k20.com. (
                        2026100110 604800 86400 2419200 604800 )
@       IN      NS      prab.k20.com.
@       IN      NS      tedd.k20.com.

2       IN      PTR     prab.k20.com.
3       IN      PTR     tedd.k20.com.
4       IN      PTR     obladi.k20.com.
5       IN      PTR     desmond.k20.com.
6       IN      PTR     oblada.k20.com.
7       IN      PTR     molly.k20.com.
```

### 2. Konfigurasi Reverse Zones pada tedd (Slave)

File `/etc/bind/named.conf.local`:
```named
zone "2.221.192.in-addr.arpa" {
    type slave;
    masters { 192.221.5.2; };
    file "/var/lib/bind/2.221.192.in-addr.arpa";
};

zone "4.221.192.in-addr.arpa" {
    type slave;
    masters { 192.221.5.2; };
    file "/var/lib/bind/4.221.192.in-addr.arpa";
};

zone "5.221.192.in-addr.arpa" {
    type slave;
    masters { 192.221.5.2; };
    file "/var/lib/bind/5.221.192.in-addr.arpa";
};
```

### 3. Hasil Pengujian PTR Lookups

```text
root@gamma:~# host -t PTR 192.221.2.2
2.2.221.192.in-addr.arpa domain name pointer abbey.k20.com.

root@gamma:~# host -t PTR 192.221.4.2
2.4.221.192.in-addr.arpa domain name pointer penny.k20.com.

root@gamma:~# host -t PTR 192.221.5.4
4.5.221.192.in-addr.arpa domain name pointer obladi.k20.com.

root@gamma:~# host -t PTR 192.221.5.5
5.5.221.192.in-addr.arpa domain name pointer desmond.k20.com.

root@gamma:~# host -t PTR 192.221.5.6
6.5.221.192.in-addr.arpa domain name pointer oblada.k20.com.

root@gamma:~# host -t PTR 192.221.5.7
7.5.221.192.in-addr.arpa domain name pointer molly.k20.com.
```

<img width="850" height="250" alt="Bukti Pengujian Soal 8" src="https://github.com/user-attachments/assets/placeholder-soal-8" />

---

## Soal 9

Menjalankan layanan web statis berbasis Apache2 pada node area vault (`obladi` dan `desmond`). Mengaktifkan fitur `autoindex` (directory listing) pada path `/arsip/` sehingga seluruh daftar file dapat ditelusuri langsung melalui browser/HTTP client menggunakan hostname.

*(Konfigurasi node `desmond` identik dengan `obladi`)*

### 1. Konfigurasi Apache pada obladi (192.221.5.4)

File `/etc/apache2/sites-available/000-default.conf`:
```apache
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
```

Modul yang diaktifkan:
```bash
a2enmod autoindex rewrite
service apache2 restart
```

Pembuatan file arsip:
```bash
mkdir -p /var/www/html/arsip
echo "Arsip Rahasia The Mesh - Vault Obladi Node" > /var/www/html/arsip/arsip_obladi.txt
echo "Laporan Eksekusi Vault 2026" > /var/www/html/arsip/laporan.txt
```

### 2. Hasil Pengujian

Mengakses direktori `/arsip/` melalui hostname `vault.k20.com`:
```text
root@gamma:~# curl -s http://vault.k20.com/arsip/ | grep -E "(Index of|arsip_|laporan)"
<title>Index of /arsip</title>
<h1>Index of /arsip</h1>
<a href="arsip_obladi.txt">arsip_obladi.txt</a>
<a href="laporan.txt">laporan.txt</a>
```

Mengakses isi dokumen arsip:
```text
root@gamma:~# curl -s http://vault.k20.com/arsip/arsip_obladi.txt
Arsip Rahasia The Mesh - Vault Obladi Node
```

<img width="850" height="250" alt="Bukti Pengujian Soal 9" src="https://github.com/user-attachments/assets/placeholder-soal-9" />

---

## Soal 10

Menjalankan layanan web dinamis berbasis Nginx + PHP-FPM pada node area core (`oblada` dan `molly`). Dibuat aplikasi sederhana dengan halaman beranda (`index.php`) dan halaman profil (`profil.php`). Diterapkan aturan rewrite sehingga akses ke `/profil` berfungsi dengan URL bersih (clean URL) tanpa akhiran `.php`.

*(Konfigurasi node `molly` identik dengan `oblada`)*

### 1. File Aplikasi PHP pada oblada (192.221.5.6)

File `/var/www/core/index.php`:
```php
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
```

File `/var/www/core/profil.php`:
```php
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
```

### 2. Konfigurasi Nginx pada oblada

File `/etc/nginx/sites-available/core.conf`:
```nginx
server {
    listen 80;
    server_name oblada.k20.com oblada.k-20.com core.k20.com core.k-20.com static.k20.com static.k-20.com www.k20.com www.k-20.com _;
    root /var/www/core;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    # Aturan clean URL rewrite: /profil -> /profil.php
    location /profil {
        rewrite ^/profil/?$ /profil.php last;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
        fastcgi_param HTTP_X_REAL_IP $http_x_real_ip;
    }
}
```

### 3. Hasil Pengujian

Akses halaman beranda melalui hostname:
```text
root@gamma:~# curl -s http://oblada.k20.com/ | grep "Core Dynamic Application"
  <h1>Core Dynamic Application (Node: oblada - 192.221.5.6)</h1>
```

Akses clean URL `/profil` tanpa akhiran `.php`:
```text
root@gamma:~# curl -s http://oblada.k20.com/profil | grep -A 3 "Halaman Profil"
  <h1>Halaman Profil Entitas</h1>
  <p>ID: Oblada-Core</p>
  <p>Peran: Dynamic Core Engine</p>
  <p>Node IP: 192.221.5.6</p>
```

<img width="850" height="250" alt="Bukti Pengujian Soal 10" src="https://github.com/user-attachments/assets/placeholder-soal-10" />

---

## Soal 11

Mengonfigurasi dua gerbang reverse proxy dan load balancer:
1. `penny` (Apache) sebagai reverse proxy load balancer menuju area vault (`obladi` & `desmond`).
2. `abbey` (Nginx) sebagai reverse proxy load balancer menuju area core (`oblada` & `molly`).
Kedua gerbang meneruskan identitas asli pengunjung ke backend melalui header `Host` dan `X-Real-IP`.

### 1. Konfigurasi Apache Reverse Proxy pada penny (192.221.4.2)

File `/etc/apache2/sites-available/000-default.conf`:
```apache
<VirtualHost *:80>
    ServerName penny.k20.com
    ServerAlias penny.k-20.com www.k20.com www.k-20.com k20.com k-20.com 192.221.4.2

    # Forwarding header Host dan X-Real-IP
    RewriteEngine On
    RewriteRule .* - [E=CLIENT_IP:%{REMOTE_ADDR}]
    RequestHeader set X-Real-IP "%{CLIENT_IP}e"
    ProxyPreserveHost On

    # Balancer cluster ke area Vault
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
```

Modul Apache yang diaktifkan:
```bash
a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests rewrite headers
service apache2 restart
```

### 2. Konfigurasi Nginx Reverse Proxy pada abbey (192.221.2.2)

File `/etc/nginx/sites-available/proxy.conf`:
```nginx
upstream core_cluster {
    server 192.221.5.6:80;
    server 192.221.5.7:80;
}

server {
    listen 80 default_server;
    server_name abbey.k20.com abbey.k-20.com static.k20.com static.k-20.com 192.221.2.2 _;

    # Forwarding header Host dan X-Real-IP
    location / {
        proxy_pass http://core_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### 3. Hasil Pengujian Load Balancing & Header Forwarding

Pengujian distribusi load balancing pada Penny (Apache):
```text
root@gamma:~# for i in 1 2 3 4; do curl -s http://penny.k20.com/ | grep "Vault Static Repository ("; done
  <h1>Vault Static Repository (obladi - 192.221.5.4)</h1>
  <h1>Vault Static Repository (desmond - 192.221.5.5)</h1>
  <h1>Vault Static Repository (obladi - 192.221.5.4)</h1>
  <h1>Vault Static Repository (desmond - 192.221.5.5)</h1>
```

Pengujian distribusi load balancing pada Abbey (Nginx):
```text
root@gamma:~# for i in 1 2 3 4; do curl -s http://abbey.k20.com/ | grep "Node:"; done
  <h1>Core Dynamic Application (Node: oblada - 192.221.5.6)</h1>
  <h1>Core Dynamic Application (Node: molly - 192.221.5.7)</h1>
  <h1>Core Dynamic Application (Node: oblada - 192.221.5.6)</h1>
  <h1>Core Dynamic Application (Node: molly - 192.221.5.7)</h1>
```

Pengujian penerusan header `X-Real-IP` (klien gamma dengan IP `192.221.1.4`):
```text
root@gamma:~# curl -s http://abbey.k20.com/ | grep "Visitor IP detected:"
  <p>Visitor IP detected: 192.221.1.4</p>
```

<img width="850" height="250" alt="Bukti Pengujian Soal 11" src="https://github.com/user-attachments/assets/placeholder-soal-11" />

---

## Soal 12

Penerapan proteksi Basic Authentication untuk path `/admin` pada gerbang `penny`. Akses tanpa kredensial atau dengan kredensial salah akan ditolak (`HTTP 401 Unauthorized`), dan hanya diizinkan masuk jika menggunakan kredensial:
- **Username:** `prabs`
- **Password:** `pakar_pinter_jadi_gob***`

### 1. Konfigurasi Basic Authentication pada penny

Pembuatan file kredensial `.htpasswd`:
```bash
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

htpasswd -bc /etc/apache2/.htpasswd prabs "pakar_pinter_jadi_gob***"
chmod 640 /etc/apache2/.htpasswd
chown root:www-data /etc/apache2/.htpasswd
```

Konfigurasi VirtualHost `/etc/apache2/sites-available/000-default.conf`:
```apache
# Pengecualian path /admin dari reverse proxy
ProxyPass /admin !

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
```

### 2. Hasil Pengujian

Akses tanpa kredensial (ditolak `401 Unauthorized`):
```text
root@gamma:~# curl -s -i http://penny.k20.com/admin | head -n 6
HTTP/1.1 401 Unauthorized
Date: Wed, 30 Sep 2026 16:23:00 GMT
Server: Apache/2.4.68 (Debian)
WWW-Authenticate: Basic realm="Restricted Syndicate Area"
Content-Length: 500
Content-Type: text/html; charset=iso-8859-1
```

Akses dengan kredensial salah (ditolak `401 Unauthorized`):
```text
root@gamma:~# curl -s -i -u admin:wrongpass http://penny.k20.com/admin | head -n 1
HTTP/1.1 401 Unauthorized
```

Akses dengan kredensial valid (berhasil `200 OK`):
```text
root@gamma:~# curl -s -i -u 'prabs:pakar_pinter_jadi_gob***' http://penny.k20.com/admin
HTTP/1.1 200 OK
Date: Wed, 30 Sep 2026 16:23:07 GMT
Server: Apache/2.4.68 (Debian)
Content-Type: text/html

<!DOCTYPE html>
<html>
<head><title>Dokumen Rahasia Sindikat</title></head>
<body>
  <h1>Dokumen Rahasia Sindikat - Area Terbatas /admin</h1>
  <p>Autentikasi Berhasil. Selamat datang, prabs.</p>
</body>
</html>
```

<img width="850" height="250" alt="Bukti Pengujian Soal 12" src="https://github.com/user-attachments/assets/placeholder-soal-12" />

---

## Soal 13

Konfigurasi redirect kanonikal pada kedua gerbang:
1. Akses ke IP `penny` (`192.221.4.2`) dan domain `penny.k20.com` dipaksa redirect permanen (`HTTP 301`) menuju `www.k20.com`.
2. Akses ke IP `abbey` (`192.221.2.2`) dan domain `abbey.k20.com` dipaksa redirect sementara (`HTTP 302`) menuju `static.k20.com`.

### 1. Konfigurasi Redirect 301 pada Apache penny (192.221.4.2)

File `/etc/apache2/sites-available/000-default.conf`:
```apache
# Redirect permanen 301 untuk IP dan penny.k20.com -> www.k20.com
<VirtualHost *:80>
    ServerName penny.k20.com
    ServerAlias 192.221.4.2
    Redirect 301 / http://www.k20.com/
</VirtualHost>

<VirtualHost *:80>
    ServerName penny.k-20.com
    Redirect 301 / http://www.k-20.com/
</VirtualHost>

# VirtualHost utama kanonikal www.k20.com
<VirtualHost *:80>
    ServerName www.k20.com
    ServerAlias www.k-20.com k20.com k-20.com
    DocumentRoot /var/www/html

    # Reverse proxy dan auth /admin tetap berjalan di virtualhost ini
    ...
</VirtualHost>
```

### 2. Konfigurasi Redirect 302 pada Nginx abbey (192.221.2.2)

File `/etc/nginx/sites-available/proxy.conf`:
```nginx
upstream core_cluster {
    server 192.221.5.6:80;
    server 192.221.5.7:80;
}

# Redirect sementara 302 untuk IP dan abbey.k20.com -> static.k20.com
server {
    listen 80;
    server_name 192.221.2.2 abbey.k20.com;
    return 302 http://static.k20.com$request_uri;
}

server {
    listen 80;
    server_name abbey.k-20.com;
    return 302 http://static.k-20.com$request_uri;
}

# Server utama kanonikal static.k20.com
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
```

### 3. Hasil Pengujian

Pengujian Redirect 301 pada Penny:
```text
root@gamma:~# curl -s -i http://192.221.4.2/ | head -n 5
HTTP/1.1 301 Moved Permanently
Date: Wed, 30 Sep 2026 16:28:32 GMT
Server: Apache/2.4.68 (Debian)
Location: http://www.k20.com/
Content-Length: 344

root@gamma:~# curl -s -i http://penny.k20.com/ | head -n 5
HTTP/1.1 301 Moved Permanently
Date: Wed, 30 Sep 2026 16:28:32 GMT
Server: Apache/2.4.68 (Debian)
Location: http://www.k20.com/
Content-Length: 346
```

Pengujian Redirect 302 pada Abbey:
```text
root@gamma:~# curl -s -i http://192.221.2.2/ | grep -E "(HTTP/1.1 302|Location:)"
HTTP/1.1 302 Moved Temporarily
Location: http://static.k20.com/

root@gamma:~# curl -s -i http://abbey.k20.com/ | grep -E "(HTTP/1.1 302|Location:)"
HTTP/1.1 302 Moved Temporarily
Location: http://static.k20.com/
```

Pengujian Akses Langsung ke Domain Kanonikal (`HTTP 200 OK` tanpa loop redirect):
```text
root@gamma:~# curl -s -i http://www.k20.com/ | head -n 1
HTTP/1.1 200 OK

root@gamma:~# curl -s -i http://static.k20.com/ | head -n 1
HTTP/1.1 200 OK
```

Pengujian Akses dengan Mengikuti Redirect (`curl -L`):
```text
root@gamma:~# curl -s -L http://penny.k20.com/ | grep "Vault Static Repository ("
  <h1>Vault Static Repository (obladi - 192.221.5.4)</h1>

root@gamma:~# curl -s -L http://abbey.k20.com/ | grep "Core Dynamic Application"
  <h1>Core Dynamic Application (Node: oblada - 192.221.5.6)</h1>
```

<img width="850" height="250" alt="Bukti Pengujian Soal 13" src="https://github.com/user-attachments/assets/placeholder-soal-13" />

---
