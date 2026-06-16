# Scenario 22 - SNI (Server Name Indication) Misconfiguration

## Symptom

Multiple sites on ONE IP address

Accessing site-a.com returns site-b.com's certificate!

Error: 

    "wrong certificate served"

Old clients get the WRONG site entirely

## Server Name Indication (SNI) Definition

One server, one IP, MANY HTTPS sites?

SNI lets the client say "I want site-a.com" DURING the TLS handshake so the server knows WHICH certificate to present.

Without SNI: Server doesn't know which cert to serve ❌

With SNI:    Client tells server upfront ✅

## Diagnostics

### 1) Test without SNI (old client behavior)

    openssl s_client -connect 192.168.1.10:443 2>/dev/null | openssl x509 -noout -subject

 Returns the DEFAULT cert (might be wrong site!)

 ### 2) Test with SNI

    openssl s_client -connect 192.168.1.10:443 -servername site-a.com 2>/dev/null | openssl x509 -noout -subject

Should return site-a.com's cert ✅

### 3) Compare results

If they differ → SNI is working, but client may not support it

If WITH SNI returns wrong cert → server misconfiguration

### 4) Check which clients don't support SNI

Very old clients: IE on Windows XP, Android < 3.0, Java 6

## Fix

### Nginx SNI Configuration

    # Default server (served when SNI not provided or no match)
    server {
        listen 443 ssl default_server;
        server_name _;
        ssl_certificate     /etc/ssl/default.crt;
        ssl_certificate_key /etc/ssl/default.key;
        return 444;  # Close connection for unknown hosts
    }
    
    # Site A
    server {
        listen 443 ssl;
        server_name site-a.com;
        ssl_certificate     /etc/ssl/site-a.crt;    ← Correct cert
        ssl_certificate_key /etc/ssl/site-a.key;
    }
    
    # Site B
    server {
        listen 443 ssl;
        server_name site-b.com;
        ssl_certificate     /etc/ssl/site-b.crt;    ← Correct cert
        ssl_certificate_key /etc/ssl/site-b.key;
    }

### For Client without SNI

Use a multi-domain SAN certificate
   
One cert covering site-a.com AND site-b.com
   
Works even without SNI ✅

### Use separate IP addresses per site

Each site gets its own IP — no SNI needed
   
More expensive but bulletproof

### Drop support for legacy clients

Modern reality: SNI is supported by 99%+ of clients
