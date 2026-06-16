# Scenario 1 - Certificate Expired

## Diagnostics

### 1) Check certificate dates

    echo | openssl s_client -connect yoursite.com:443 2>/dev/null | openssl x509 -noout -dates

### 2) How long has it been expired?

    openssl s_client -connect yoursite.com:443 2>/dev/null | openssl x509 -noout -enddate

### 3) Which server/load balancer serves the cert?

Find IP

    dig yoursite.com

Confirm open port

    nmap -p 443 yoursite.com

## Fix

Manual

### 1) Generate Certificate Signing Request (CSR)

    openssl req -new -key private.key -out new.csr -subj "/CN=yoursite.com/O=YourOrg"

### 2) Submit CSR to your Certificate Authority (CA)

### 3) Install new certificate

### 4) Reload web server

Let's encrypt / Certbot

### 1) Renew certificate

    certbot renew --force-renewal

### 2) Restart server

Nginx

    systemctl reload nginx

Apache2

    systemctl reload apache2

## Prevention

□ Set up monitoring alerts at 30, 14, 7 days before expiry
□ Use automated renewal (certbot, cert-manager)
□ Use short-lived certs (90 days) — forces automation
