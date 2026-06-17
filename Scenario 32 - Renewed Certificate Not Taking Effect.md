# Scenario 32 - Renewed Certificate Not Taking Effect

## Symptom

You renewed the certificate ✅

New cert file is in place ✅

But the server STILL serves the OLD certificate! ❌

openssl shows old expiry date

## Diagnostics

### 1) Verify the file on disk is the NEW cert

    openssl x509 -in /etc/ssl/server.crt -noout -dates

#### Shows NEW dates ✅

### 2) Check what the server ACTUALLY serves

    echo | openssl s_client -connect localhost:443 2>/dev/null | openssl x509 -noout -dates

#### Shows OLD dates ❌ ← Server didn't reload!

### 3) Check if process was reloaded

    systemctl status nginx
    ps aux | grep nginx

#### Check process start time vs cert install time

### 4) Check for cached certs in memory

Some apps cache certs at startup!

## Causes and fixes

### 1) Forgot to reload the service

#### Fix

Nginx

    nginx -s reload

Apache

    systemctl reload apache2

HAProxy

    systemctl restart haproxy

### 2) Load balancer caching old cert

#### Fix

Update cert on the Load Balancer, not just backend.

### 3) Multiple processes/workers

#### Fix

Full restart, not just reload

    systemctl restart nginx

### 4) Application caches cert in memory at startup

#### Fix

Restart the application

### 5) Kubernetes secret updated put pods not restarted

#### Fix

Restart pods to pick up new secret

    kubectl rollout restart deployment/my-app -n my-namespace

### 6) CDN Caching the certificate

#### Fix

Cloudflare/CloudFront serves its own cert. Update there.

### 7) Wrong cert file path in config

#### Fix

Verify config points to the file you actually updated.

    grep ssl_certificate /etc/nginx/nginx.conf

## Automated reload after renewal

### 1) Certbot

Certbot deploy hook, auto-reload after renewal

    certbot renew --deploy-hook "systemctl reload nginx"

OR create a renewal script

    cat > /etc/letsencrypt/renewal-hooks/deploy/reload.sh << 'EOF'
    #!/bin/bash
    systemctl reload nginx
    systemctl reload postfix
    docker exec myapp kill -HUP 1
    EOF

    chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload.sh
