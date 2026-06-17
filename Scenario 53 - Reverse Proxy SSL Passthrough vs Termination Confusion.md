# Scenario 53 - Reverse Proxy SSL Passthrough vs Termination Confusion.md

## Symptom

Backend expects to do its own TLS

But proxy is terminating SSL!

Double encryption errors

"unexpected HTTP request" on HTTPS port

Backend cert never used despite being configured

## Diagnostics

### 1) Determine current proxy mode

Is the proxy TERMINATING or PASSING THROUGH?

#### Termination: proxy decrypts, backend gets HTTP

#### Passthrough: proxy forwards encrypted, backend decrypts

### 2) Check which cert is presented

    echo | openssl s_client -connect public-host:443 2>/dev/null | openssl x509 -noout -subject

Is it the proxy's cert or the backend's cert?

### 3) Check backend directly

    echo | openssl s_client -connect backend:8443 2>/dev/null | openssl x509 -noout -subject

## SSL Passthrough vs Termination

    🔓 SSL TERMINATION (most common):
       Client ──HTTPS──► Proxy ──HTTP──► Backend
       - Proxy holds the cert
       - Backend gets plain HTTP
       - Proxy can inspect/route based on content
    
    🔒 SSL PASSTHROUGH:
       Client ──HTTPS──────────────────► Backend
                    (proxy just forwards bytes)
       - Backend holds the cert
       - End-to-end encryption
       - Proxy CANNOT see content (routes by SNI only)

## Fix

### Nginx SSL Passthrough (stream module)

    # Passthrough — proxy forwards encrypted traffic by SNI
    stream {
        map $ssl_preread_server_name $backend {
            app1.company.com  backend1:8443;
            app2.company.com  backend2:8443;
        }
    
        server {
            listen 443;
            ssl_preread on;              # Read SNI without decrypting
            proxy_pass $backend;          # Forward encrypted as-is
        }
    }

### HAProxy SSL Passthrough

    # HAProxy passthrough mode
    frontend https_in
        bind *:443
        mode tcp                          # TCP mode = passthrough!
        tcp-request inspect-delay 5s
        tcp-request content accept if { req_ssl_hello_type 1 }
        use_backend backend_app if { req_ssl_sni -i app.company.com }
    
    backend backend_app
        mode tcp
        server app1 backend:8443          # No SSL config = passthrough
