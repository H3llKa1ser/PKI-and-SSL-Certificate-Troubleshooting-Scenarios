# Scenario 71 - Mutual TLS with Client Cert in Header (Proxy Stripping)

## Symptom

mTLS terminated at load balancer

Backend needs client cert info but doesn't get it

"client certificate not available" in app

LB strips the cert after validation

App can't identify the client

## Diagnostics

### 1) Understand the flow

Client ──mTLS──► LB (validates cert) ──HTTP──► Backend

Backend gets HTTP — cert info is GONE unless forwarded!

### 2) Check if LB forwards cert info in headers

    curl -v https://app/debug 2>&1 | grep -i "x-client\|x-ssl\|x-forwarded-client"

Common forwarded headers:

    # X-SSL-Client-Cert
    # X-Client-Cert
    # X-Forwarded-Client-Cert (Envoy/Istio: XFCC)

### 3) Check LB configuration

Is it configured to pass cert details downstream?

## Fix

### Nginx Forward Client Cert

    server {
        listen 443 ssl;
        ssl_client_certificate /etc/ssl/ca.crt;
        ssl_verify_client on;
    
        location / {
            proxy_pass http://backend;
            # Forward client cert details to backend
            proxy_set_header X-SSL-Client-Cert $ssl_client_escaped_cert;
            proxy_set_header X-SSL-Client-DN   $ssl_client_s_dn;
            proxy_set_header X-SSL-Client-Verify $ssl_client_verify;
            proxy_set_header X-SSL-Client-Serial $ssl_client_serial;
        }
    }

### Istio/Envoy XFCC

    # Envoy forwards X-Forwarded-Client-Cert automatically
    # Configure what to include:
    apiVersion: networking.istio.io/v1beta1
    kind: EnvoyFilter
    spec:
      configPatches:
      - applyTo: NETWORK_FILTER
        patch:
          value:
            typed_config:
              forward_client_cert_details: SANITIZE_SET
              set_current_client_cert_details:
                subject: true
                dns: true
                uri: true

### Python

    # Backend reads the forwarded cert
    # Flask example
    from flask import request
    import urllib.parse
    
    @app.route('/api')
    def api():
        client_cert = request.headers.get('X-SSL-Client-Cert')
        client_dn = request.headers.get('X-SSL-Client-DN')
        verify = request.headers.get('X-SSL-Client-Verify')
        if verify != 'SUCCESS':
            return 'Client cert validation failed', 403
        # Use client_dn to identify the client

#### Note: Backend MUST only trust these headers from the LB, never from clients directly! Strip them at the edge. 

