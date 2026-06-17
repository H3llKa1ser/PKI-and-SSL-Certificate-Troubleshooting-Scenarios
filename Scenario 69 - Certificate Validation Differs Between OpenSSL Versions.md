# Scenario 69 - Certificate Validation Differs Between OpenSSL Versions

## Symptom

Cert validates with OpenSSL 1.0.2 ✅

Fails with OpenSSL 3.0 ❌

"unsupported" or "legacy" errors after upgrade

Old algorithms rejected by new OpenSSL

"digital envelope routines::unsupported"

## Diagnostics

### 1) Check OpenSSL version

    openssl version

### 2) Test what changed

OpenSSL 3.0 deprecated many legacy algorithms!

    openssl x509 -in cert.crt -noout -text | grep "Signature Algorithm"

### 3) Check if legacy provider is needed

    openssl list -providers

OpenSSL 3.0 moved old algos to "legacy" provider

### 4) Test with legacy provider

    openssl x509 -in cert.crt -noout -text -provider legacy -provider default

## What Changed in OpenSSL 3.0

    ❌ Deprecated by default:
       - MD2, MD4, MDC2
       - DES, RC4, RC2, Blowfish
       - SEED, IDEA, CAST
       - PKCS#12 with old encryption
       - Small RSA keys (<512 in some configs)

These now require the "legacy" provider!

## Fix

### 1) Enable legacy provider (temporary bridge)

openssl.cnf:

    [provider_sect]
    default = default_sect
    legacy = legacy_sect
    
    [default_sect]
    activate = 1
    
    [legacy_sect]
    activate = 1

### 2)  Convert old PKCS#12 to modern encryption

    openssl pkcs12 -in old.pfx -nodes -legacy | openssl pkcs12 -export -out new.pfx

Re-export with modern algorithms

### 3) Reissue certs with modern algorithms (best!)

SHA-256, RSA-2048+, or ECDSA

### 4) For code requiring legacy

    OPENSSL_CONF=/path/to/legacy-enabled.cnf myapp

