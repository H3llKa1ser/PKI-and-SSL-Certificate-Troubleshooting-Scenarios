# Scenario 48 - Certificate Key Size Too Small / Weak Algorithm

## Symptom

Browser: "Weak security" / "Obsolete cryptography"

Security scanner flags: "Weak key (1024-bit)"

"SHA-1 signature is deprecated"

Modern browsers reject the certificate entirely

Compliance audit failure (PCI-DSS, NIST)

## Diagnostics

### 1) Check key size

    openssl x509 -in cert.crt -noout -text | grep "Public-Key"

"Public-Key: (2048 bit)" ✅

"Public-Key: (1024 bit)" ❌ TOO WEAK!

### 2) Check signature algorithm

    openssl x509 -in cert.crt -noout -text | grep "Signature Algorithm"


"sha256WithRSAEncryption" ✅

"sha1WithRSAEncryption"   ❌ DEPRECATED!

"md5WithRSAEncryption"    ❌ BROKEN!

### 3) Audit entire chain

    openssl s_client -connect host:443 -showcerts 2>/dev/null | awk '/BEGIN/,/END/' | csplit -sz -f c- - '/BEGIN/' '{*}'
    for c in c-*; do
      echo "=== $c ==="
      openssl x509 -in $c -noout -text | grep -E "Public-Key|Signature Algorithm"
    done

## Current minimum standards 2026

    🔑 RSA:        Minimum 2048-bit (3072+ recommended)
    🔑 ECDSA:      Minimum 256-bit (P-256)
    🔏 Signature:  SHA-256 minimum (SHA-1 and MD5 BANNED)
    🚫 Forbidden:  RSA-1024, SHA-1, MD5, RC4, DES, 3DES

## Fix

### Generate a strong new key and CSR

RSA 2048 (or 4096 for extra security)

    openssl genrsa -out new-private.key 2048

    openssl req -new -sha256 -key new-private.key -out new.csr -subj "/CN=yoursite.com"

OR ECDSA (faster, modern)

    openssl ecparam -genkey -name prime256v1 -out new-ec.key

    openssl req -new -sha256 -key new-ec.key -out new-ec.csr -subj "/CN=yoursite.com"

Submit new CSR to CA, install the new strong certificate

