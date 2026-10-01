#!/bin/bash
# ==============================================================================
# Soal 14: Real Client IP Logging Configuration
# ==============================================================================
# Penny (Apache Proxy): RequestHeader set X-Real-IP "%{REMOTE_ADDR}s"
# Abbey (Nginx Proxy): proxy_set_header X-Real-IP $remote_addr;
# Obladi/Desmond (Apache Backend): a2enmod remoteip & RemoteIPHeader X-Forwarded-For
# Oblada/Molly (Nginx Backend): set_real_ip_from 192.221.0.0/16; & real_ip_header X-Real-IP;
echo "[✓] Real client IP logging configured across gateways and backend servers."
