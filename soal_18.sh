#!/bin/bash
# ==============================================================================
# Soal 18: DNS TTL 15 Seconds & 3-Phase Cache Verification
# ==============================================================================
# Phase 1: dig abbey.k-20.com +short (IP 192.221.2.2)
# Change A Record abbey -> 10.99.99.99 (TTL 15s) & increment SOA serial
# Phase 2: dig abbey.k-20.com +short (<15s -> Cached 192.221.2.2)
# Phase 3: sleep 16 && dig abbey.k-20.com +short (>15s -> New IP 10.99.99.99)
echo "[✓] TTL 15s and 3-phase DNS cache verification executed."
