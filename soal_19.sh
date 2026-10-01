#!/bin/bash
# ==============================================================================
# Soal 19: External CNAME Outbound (outbound.k-20.com -> http.badssl.com.)
# ==============================================================================
dig CNAME outbound.k-20.com +short
curl -L http://outbound.k-20.com
