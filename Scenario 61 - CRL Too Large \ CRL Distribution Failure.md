# Scenario 61 - CRL Too Large / CRL Distribution Failure

## Symptom

Certificate validation extremely slow

CRL download times out

"CRL is too large" errors

Clients hang trying to download multi-MB CRL

Revocation checking disabled due to failures

## Diagnostics

### 1) Find the CRL distribution point

    openssl x509 -in cert.crt -noout -text | grep -A4 "CRL Distribution"

### 2) Download and check CRL size

    CRL_URL=$(openssl x509 -in cert.crt -noout -text | grep -A1 "CRL Distribution" | grep URI | sed 's/.*URI://')

    curl -o crl.der "$CRL_URL"

    ls -lh crl.der

If multiple MB → too large!

### 3) Count revoked certs in the CRL 

    openssl crl -in crl.der -inform DER -noout -text | grep -c "Serial Number"

### 4) Check CRL validity/freshness

    openssl crl -in crl.der -inform DER -noout -lastupdate -nextupdate

## Why CRLs (Certificate Revocation List) get huge

Every revoked cert adds an entry to the CRL

A busy CA with millions of certs = massive CRL

Downloading a 50MB CRL on every connection = disaster!

This is WHY OCSP and OCSP stapling were invented.

## Fix

### 1) Use OCSP instead of CRL (preferred)

OCSP checks ONE cert, not the whole list

Configure clients to prefer OCSP

### 2) Use OCSP Stapling (best)

Server staples OCSP response — client downloads nothing

    ssl_stapling on;
    ssl_stapling_verify on;

### 3) Implement partitioned CRLs (CRL Distribution points)

Split one giant CRL into many smaller ones

Each cert points to a specific smaller CRL partition

### 4) Use Delta CRLs

Base CRL + small "delta" of recent changes

Clients download base once, then small deltas

### 5) For internal PKI — tune CRL publishing

Shorter validity = smaller CRLs but more frequent updates

    certutil -setreg CA\CRLPeriodUnits 1
    certutil -setreg CA\CRLPeriod "Days"
