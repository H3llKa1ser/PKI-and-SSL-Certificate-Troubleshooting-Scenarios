# Scenario 10: OCSP / Revocation Check Failing

## Symptom

Some clients get SSL errors even with a valid certificate

Slow TLS connections (OCSP timeout)

Error: 

    "certificate revocation check failed"

## Diagnostics

### 1) Test OCSP manually

First, get OCSP URL from the certificate

    openssl x509 -in server.crt -noout -text | grep "OCSP"

Output: OCSP - URI:http://ocsp.yourca.com

### 2) Test OCSP response

    openssl ocsp -issuer intermediate-ca.crt -cert server.crt -url http://ocsp.yourca.com -resp_text

Good output:

    Response verify OK
    server.crt: good         ← Certificate is GOOD ✅

Bad output:

    server.crt: revoked      ← Certificate is REVOKED ❌
    server.crt: unknown      ← OCSP can't find it ⚠️

### 3) Check OCSP Stapling on server

    openssl s_client -connect example.com:443 -status 2>/dev/null | grep -A 10 "OCSP Response"

Should show "OCSP Response Status: successful" ✅

