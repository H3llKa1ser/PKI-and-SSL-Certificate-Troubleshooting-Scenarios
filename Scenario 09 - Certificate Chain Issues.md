# Scenario 9: Certificate Chain Issues

## Symptom

Works in browser ✅ but fails in:
  - curl ❌
  - Java applications ❌
  - Mobile apps ❌
  - API clients ❌

## Diagnostics

### 1) Check the chain being served

    openssl s_client -connect example.com:443 -showcerts 2>/dev/null

If you only see depth 0 ← INCOMPLETE CHAIN!

### 2) Use SSL Labs

    https://ssllabs.com

Look for "Chain Issues: Incomplete" warning

## Fix

### Build the full chain

Combine certs into fullchain file (order matters!)

    cat server.crt intermediate-ca.crt > fullchain.crt

If 3-tier PKI:

    cat server.crt intermediate-ca.crt root-ca.crt > fullchain.crt

Verify the chain is correct

    openssl verify -CAfile root-ca.crt -untrusted intermediate-ca.crt server.crt
  
Output should be: server.crt: OK ✅
