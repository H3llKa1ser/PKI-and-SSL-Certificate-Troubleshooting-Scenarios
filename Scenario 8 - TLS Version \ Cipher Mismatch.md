# Scenario 8 - TLS Version / Cipher Mismatch

## Symptom

curl:

    (35) error:1409442E:SSL routines:ssl3_read_bytes:tlsv1 alert protocol version

Error: 

    "No cipher suites in common"

Old application cannot connect to upgraded server

## Diagnostics

### 1) Check what TLS versions the server supports

    nmap --script ssl-enum-ciphers -p 443 example.com

### 2) Test specific TLS version

TLS 1.0

    openssl s_client -connect example.com:443 -tls1 

TLS 1.1

    openssl s_client -connect example.com:443 -tls1_1 

TLS 1.2

    openssl s_client -connect example.com:443 -tls1_2  

tls 1.3

    openssl s_client -connect example.com:443 -tls1_3  

### 3) Checl SSL Labs for full analysis

    https://www.ssllabs.com/ssltest/analyze.html?d=example.com

### 4) Check what cipher suites the client supports

    openssl ciphers -v 'ALL'

## Fix

### Secure Nginx TLS Configuration

    server {
        listen 443 ssl;
    
        # Certificates
        ssl_certificate     /etc/ssl/fullchain.crt;
        ssl_certificate_key /etc/ssl/private.key;
    
        # Only allow TLS 1.2 and 1.3 ✅
        ssl_protocols TLSv1.2 TLSv1.3;
    
        # Strong cipher suites only
        ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;
    
        # HSTS — force HTTPS
        add_header Strict-Transport-Security "max-age=63072000" always;
    
        # OCSP Stapling
        ssl_stapling on;
        ssl_stapling_verify on;
    }

