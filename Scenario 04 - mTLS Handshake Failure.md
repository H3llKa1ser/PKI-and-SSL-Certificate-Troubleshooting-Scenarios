# Scenario 4 - mTLS Handshake Failure

## Symptom

#### Service A cannot connect to Service B

Error: 

    "tls: certificate required"

Error: 

    "tls: bad certificate"

Error: 

    "remote error: tls: unknown certificate authority"

HTTP 400: 

    "No required SSL certificate was sent"

## Diagnostics

### 1) Test mTLS connection manually

    openssl s_client -connect service-b:8443 -cert client.crt -key client.key -CAfile ca.crt -verify_return_error

client.crt = Client Certificate

client.key = Client private key

ca.crt = CA to verify server

### 2) Check if server requires client cert

    openssl s_client -connect service-b:8443 2>&1 | grep "Acceptable client"

#### If output shows CAs = your CA, server wants a client cert!

### 3) Verify client cert is signed by server-trusted CA

    openssl verify -CAfile server-trusted-ca.crt client.crt

### 4) Check cert key usage

    openssl x509 -in client.crt -text -noout | grep -A5 "Key Usage"


#### Must show: TLS Web Client Authentication ✅

## Common Causes

    ❌ Client not sending its certificate
    ❌ Client cert signed by CA the server doesn't trust
    ❌ Client cert missing "Client Authentication" key usage
    ❌ Expired client certificate
    ❌ Wrong cert/key pair (cert from one CA, key from another)
    ❌ Server not configured to request client cert

## Fix

### 1) Check if cert and key are a matching pair

Cert

    openssl x509 -noout -modulus -in client.crt | openssl md5

Key

    openssl rsa -noout -modulus -in client.key | openssl md5

#### Both commands must produce the SAME hash!

If hashes match ✅ — correct pair

If hashes differ ❌ — wrong key for this cert!

### Nginx mTLS configuration

    server {
      listen 443 ssl;
    
      ssl_certificate     /etc/ssl/server.crt;
      ssl_certificate_key /etc/ssl/server.key;
    
      # mTLS configuration
      ssl_client_certificate /etc/ssl/trusted-ca.crt;   # CA to verify clients
      ssl_verify_client on;                              # Require client cert ✅
      ssl_verify_depth 2;                                # Check chain depth
    }

