# Scenario 68 - Certificate Fails Only on First Request After Idle.md

## Symptom

First request after period of inactivity fails

Subsequent requests work fine

"connection reset during handshake"

OCSP stapling cache expired during idle

Cold-start TLS failures

## Diagnostics

### 1) Reproduce the cold-start

Wait for idle period, then test

    sleep 3600 && curl -v https://host 2>&1 | grep -i "ssl\|error"

### 2) Check OCSP staple cache lifetime

    echo | openssl s_client -connect host:443 -status 2>/dev/null | grep -A2 "Next Update"

If staple expired during idle → first request refreshes it (slow/fail)

### 3) Check for connection pool/keepalive issues

    ss -tnp | grep :443

Stale connections in pool may have expired sessions

## Fix

### 1) Pre-fetch OCSP staple on startup

    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/ssl/chain.crt;
    resolver 1.1.1.1 valid=300s;

### 2) Keep OCSP cache warm with a health check

Cron job that hits the endpoint periodically

    * * * * * curl -s https://host/health > /dev/null

### 3) Tune session cache to survive idle

    ssl_session_cache shared:SSL:50m;
    ssl_session_timeout 1d;        # Longer = survives idle better

### 4) Connection pool validation

Configure pools to validate/recycle idle connections

Most pools have a "test on borrow" or max-idle-time setting
