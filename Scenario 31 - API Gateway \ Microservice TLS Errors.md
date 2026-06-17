# Scenario 31 - API Gateway \ Microservice TLS Errors

## Symptom

API Gateway can't reach backend microservice over TLS

502 Bad Gateway

"upstream SSL certificate verify error"

Works direct to service, fails through gateway

## Diagnostics

### 1) Test gateway -> backend directly

From the gateway pod/server

    curl -v https://backend-service:8443/health --cacert /etc/certs/ca.crt

### 2) Check if gateway verifies backend cert

Common issue: gateway expects specific SAN/hostname

### 3) Test backend cert SAN

    openssl s_client -connect backend-service:8443 2>/dev/null | openssl x509 -noout -text | grep -A1 "Subject Alternative Name"

Does the SAN include the name the gateway uses to connect?

Gateway connects to: backend-service

Cert SAN must include: backend-service ✅

## Fixes

### 1) Nginx as API Gateway

    location /api/ {
        # Backend over TLS
        proxy_pass https://backend-service:8443;
    
        # Verify backend certificate
        proxy_ssl_verify on;
        proxy_ssl_trusted_certificate /etc/certs/ca.crt;
        proxy_ssl_verify_depth 2;
    
        # CRITICAL: name must match backend cert SAN!
        proxy_ssl_name backend-service.internal;
        proxy_ssl_server_name on;        # ← Send SNI to backend
    
        # For mTLS to backend
        proxy_ssl_certificate     /etc/certs/gateway-client.crt;
        proxy_ssl_certificate_key /etc/certs/gateway-client.key;
    }

### 2) Kong API Gateway

    # Kong service with TLS verification
    services:
      - name: backend-service
        url: https://backend-service:8443
        tls_verify: true
        ca_certificates:
          - <ca-cert-id>
        client_certificate:    # For mTLS
          id: <client-cert-id>

