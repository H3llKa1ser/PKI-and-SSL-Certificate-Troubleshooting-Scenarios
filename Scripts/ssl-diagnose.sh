#!/bin/bash
# ssl-diagnose.sh — Run this first for ANY SSL issue!

HOST=$1
PORT=${2:-443}

echo "🔍 SSL Diagnostics for $HOST:$PORT"
echo "=================================="

echo -e "\n📅 Certificate Dates:"
echo | openssl s_client -connect $HOST:$PORT 2>/dev/null \
  | openssl x509 -noout -dates

echo -e "\n🏷️  Certificate Subject & SANs:"
echo | openssl s_client -connect $HOST:$PORT 2>/dev/null \
  | openssl x509 -noout -subject -ext subjectAltName

echo -e "\n🔗 Certificate Chain:"
openssl s_client -connect $HOST:$PORT -showcerts 2>/dev/null \
  | grep "subject\|issuer"

echo -e "\n✅ Chain Verification:"
echo | openssl s_client -connect $HOST:$PORT 2>/dev/null \
  | openssl x509 > /tmp/server.crt
openssl verify /tmp/server.crt 2>&1

echo -e "\n🔐 TLS Protocol & Cipher:"
echo | openssl s_client -connect $HOST:$PORT 2>/dev/null \
  | grep "Protocol\|Cipher"

echo -e "\n📋 OCSP Stapling:"
openssl s_client -connect $HOST:$PORT -status 2>/dev/null \
  | grep "OCSP Response Status"

echo -e "\n⏱️  TLS Handshake Time:"
curl -o /dev/null -s \
  -w "Handshake: %{time_appconnect}s | Total: %{time_total}s\n" \
  https://$HOST:$PORT

echo -e "\n✅ Diagnostics Complete!"

# Usage:
# chmod +x ssl-diagnose.sh
# ./ssl-diagnose.sh example.com 443
