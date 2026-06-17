# Scenario 41 - gRPC / HTTP2 TLS Issues

## Symptom

gRPC service fails over TLS

"transport: authentication handshake failed"

"http2: server sent GOAWAY"

Works with HTTP/1.1 but fails with HTTP/2

ALPN negotiation failures

## Diagnostics

### 1) Check ALPN support (required for HTTP/2 and gRPC)

    openssl s_client -connect host:443 -alpn h2 2>/dev/null | grep -i "ALPN"

#### Working:

    # ALPN protocol: h2 ✅

#### Broken:

    # No ALPN negotiated ❌

### 2) Test gRPC specifically

List services

    grpcurl -insecure host:443 list  

With TLS verification

    grpcurl host:443 list

### 3) Check HTTP/2 support

    curl -v --http2 https://host 2>&1 | grep -i "http/2\|alpn"

### 4) Verify cert supports the use case

    openssl x509 -in cert.crt -noout -text | grep -A1 "Subject Alt"

## Common Issues

    ❌ ALPN not configured (HTTP/2 REQUIRES ALPN)
    ❌ Old OpenSSL without ALPN support
    ❌ Proxy/LB not passing through HTTP/2
    ❌ Cert missing proper SAN for gRPC target
    ❌ Cipher suite incompatible with HTTP/2

## Fix

### Nginx for gRPC

    server {
        listen 443 ssl http2;        # HTTP/2 enabled!
    
        ssl_certificate     /etc/ssl/server.crt;
        ssl_certificate_key /etc/ssl/server.key;
    
        # HTTP/2 requires modern TLS & ciphers
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    
        location / {
            grpc_pass grpcs://backend:50051;      # gRPC over TLS
    
            # gRPC over TLS to backend
            grpc_ssl_certificate     /etc/ssl/client.crt;
            grpc_ssl_certificate_key /etc/ssl/client.key;
            grpc_ssl_trusted_certificate /etc/ssl/ca.crt;
            grpc_ssl_verify on;
            grpc_ssl_name backend.internal;       # Must match SAN!
        }
    }

