# Scenario 40 - OCSP Stapling Suddenly Stops Working.md

## Symptom

SSL Labs grade dropped from A+ to A

"OCSP stapling: No"

Increased page load times

OCSP responder errors in logs

"ssl_stapling: certificate status request failed"

## Diagnostics

### 1) Test if stapling is working

    echo | openssl s_client -connect host:443 -status 2>/dev/null | grep -A 17 "OCSP response"

Working:

    # OCSP Response Status: successful (0x0)
    # Cert Status: good ✅

Broken:

    # OCSP response: no response sent ❌

### 2) Check if server can reach OCSP responder

Get OCSP URL from cert

    OCSP_URL=$(openssl x509 -in cert.crt -noout -ocsp_uri)
    echo "OCSP URL: $OCSP_URL"

Test connectivity to OCSP responder

    curl -v $OCSP_URL

### 3) Manually query OCSP

    openssl ocsp -issuer intermediate.crt -cert cert.crt -url $OCSP_URL -resp_text

### 4) Check nginx error log

    tail -f /var/log/nginx/error.log | grep -i "stapling\|ocsp"

## Issues and fixes

### 1) Server cannot reach OCSP responder (firewall/DNS)

Fix: Ensure outbound access to OCSP URL

#### Check resolver config in nginx

    resolver 8.8.8.8 1.1.1.1 valid=300s;
    resolver_timeout 5s;

### 2) OCSP responder is down (CA-side)

Fix: Usually temporary; nginx caches last good response

### 3) Missing intermediate cert for stapling

Fix: ssl_trusted_certificate must include the chain

    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/ssl/ca-chain.crt;   # ← Required!

### 4) Stapling cache expired and cannot refresh

Fix: Restart nginx to force fresh OCSP fetch

    systemctl restart nginx

### 5) DNS resolution failing in nginx

Fix: Add a working resolver (nginx needs it for OCSP!)

