# Scenario 63 - Certificate Serving Wrong Cert After IP/Vhost Change

## Symptom

Added a new virtual host

Now the WRONG site's cert is served for some requests

Default vhost catching requests it shouldn't

First-defined cert served as fallback incorrectly

## Diagnostics

### 1) Test with and without SNI

Without SNI (what's the default?)

    openssl s_client -connect SERVER_IP:443 2>/dev/null | openssl x509 -noout -subject

With SNI for each vhost

    for host in site1.com site2.com site3.com; do
      echo "=== $host ==="
      openssl s_client -connect SERVER_IP:443 -servername $host 2>/dev/null \
        | openssl x509 -noout -subject
    done

### 2) Check which server block is the default

    grep -r "default_server\|listen" /etc/nginx/sites-enabled/

### 3) Check for duplicate/conflicting server_name

    nginx -T | grep "server_name

## Fix

### 1) Explicit default server that REJECTS unknown hosts

    server {
        listen 443 ssl default_server;
        server_name _;
        ssl_certificate /etc/ssl/default.crt;
        ssl_certificate_key /etc/ssl/default.key;
        ssl_reject_handshake on;       # Nginx 1.19.4+ — reject unknown SNI!
        # Or: return 444;
    }

### 2) Ensure each vhost has UNIQUE server_name

    server {
        listen 443 ssl;
        server_name site1.com www.site1.com;    # Specific!
        ssl_certificate /etc/ssl/site1.crt;
        ssl_certificate_key /etc/ssl/site1.key;
    }

### 3) Check for typos in server_name

Validate config

    nginx -t                          

Review all

    nginx -T | grep -A2 server_name   

