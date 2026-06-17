# Scenario 43 - Cipher Suite Mismatch Between Client and Server

## Symptom

"handshake_failure"

"no cipher suites in common"

SSL_ERROR_NO_CYPHER_OVERLAP

Specific clients fail while others succeed

After a security hardening, some apps broke

## Diagnostics

### 1) List ciphers the server supports

    nmap --script ssl-enum-ciphers -p 443 host

### 2) List ciphers the client supports

    openssl ciphers -v | column -t

### 3) Find the overlap (or lack thereof)

Test a specific cipher

    openssl s_client -connect host:443 -cipher 'ECDHE-RSA-AES256-GCM-SHA384' 2>&1 | grep -i "cipher\|error"

### 4) Check what cipher gets negotiated

    echo | openssl s_client -connect host:443 2>/dev/null | grep "Cipher    :"

## Fix

### Balance security and compatibility

Modern config (Mozilla "Intermediate" — recommended)

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305;
    ssl_prefer_server_ciphers off;

Use the Mozilla SSL Configuration Generator (ssl-config.mozilla.org), it generates perfect configs for your server type and compatibility needs! 
