# Scenario 15 - Slow HTTPS TLS Performance Issues

## Symptom

HTTPS site is noticeably slower than HTTP equivalent

TLS handshake taking 500ms+ when it should be <50ms

Users complaining about slow page loads

Load balancer CPU is very high

## Diagnostics

### 1) Measure TLS handshake time

    curl -w "\n\
        DNS Lookup:       %{time_namelookup}s\n\
        TCP Connect:      %{time_connect}s\n\
        TLS Handshake:    %{time_appconnect}s\n\
        Total:            %{time_total}s\n" \
      -o /dev/null -s https://example.com

#### Good TLS handshake: < 100ms

#### Bad TLS handshake:  > 300ms ← Problem!

### 2) Check if TLS session resumption works

    openssl s_client -connect example.com:443 -reconnect 2>&1 | grep "Reuse"

#### "Reuse, TLSv1.3" ← Session resumption working ✅
#### No "Reuse" line  ← Session resumption broken ❌

### 3) Check OCSP stapling

    openssl s_client -connect example.com:443 -status 2>/dev/null | grep "OCSP Response Status"

#### "successful" ← OCSP stapling working ✅

#### No response  ← Client must do OCSP lookup (adds latency!) ❌

### 4) Check cipher suite performance

    openssl speed rsa2048 ecdsap256

#### ECDSA is significantly faster than RSA!

## Fix

### Optimize Nginx TLS

    server {
        listen 443 ssl;
    
        ssl_certificate     /etc/ssl/fullchain.crt;
        ssl_certificate_key /etc/ssl/private.key;
    
        # Use TLS 1.3 (fastest handshake - 1-RTT or even 0-RTT)
        ssl_protocols TLSv1.2 TLSv1.3;
    
        # Fast cipher suites (ECDHE = perfect forward secrecy + fast)
        ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    
        # Session resumption (avoids full handshake on reconnect!)
        ssl_session_cache   shared:SSL:10m;    # ← Cache TLS sessions
        ssl_session_timeout 1d;               # ← Reuse for 1 day
    
        # TLS session tickets (client-side resumption)
        ssl_session_tickets on;
    
        # OCSP Stapling (server fetches OCSP, client doesn't have to!)
        ssl_stapling        on;              # ← Enable stapling
        ssl_stapling_verify on;
        resolver            8.8.8.8 valid=300s;
    
        # HTTP/2 (much more efficient than HTTP/1.1 over TLS)
        listen 443 ssl http2;
    }

