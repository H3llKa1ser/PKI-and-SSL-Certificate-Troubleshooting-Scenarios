# Scenario 29 - Certificate Encoding Format Confusion.md

## Symptom

"Unable to load certificate"

"PEM routines: no start line"

"asn1 encoding routines: not enough data"

Certificate works in one tool but not another

"Expecting: TRUSTED CERTIFICATE"

## Certificate Format Cheat Sheet

    📄 PEM (.pem, .crt, .cer, .key)
       - Base64 encoded, ASCII text
       - Starts with: -----BEGIN CERTIFICATE-----
       - Most common format
    
    📦 DER (.der, .cer)
       - Binary format
       - Not human readable
       - Common in Java/Windows
    
    📦 PKCS#12 (.p12, .pfx)
       - Binary, password-protected
       - Contains cert + private key + chain
       - Common in Windows/IIS
    
    📦 PKCS#7 (.p7b, .p7c)
       - Contains certs + chain (NO private key)
       - Common in Windows/Java
    
    🔑 JKS (.jks)
       - Java KeyStore
       - Java-specific binary format

## Diagnostics

### 1) Identify the format

    file certificate.crt

### 2) Check if PEM (text)

    head -1 certificate.crt

#### -----BEGIN CERTIFICATE----- = PEM ✅

#### Binary garbage = DER or other

### 3) Try reading as PEM

    openssl x509 -in cert.crt -text -noout

If error "no start line" → it's probably DER!

## Format Conversions Fix

### 1) PEM -> DER

    openssl x509 -in cert.pem -outform DER -out cert.der

### 2) DER -> PEM

    openssl x509 -in cert.der -inform DER -out cert.pem

### 3) PEM → PKCS#12 (combine cert + key)

    openssl pkcs12 -export -in cert.pem -inkey private.key -out bundle.pfx -certfile ca-chain.pem

### 4) PKCS#12 → PEM (extract everything)

Extract certificate

    openssl pkcs12 -in bundle.pfx -clcerts -nokeys -out cert.pem

Extract Private Key

    openssl pkcs12 -in bundle.pfx -nocerts -out key.pem -nodes

Extract CA chain

    openssl pkcs12 -in bundle.pfx -cacerts -nokeys -out ca-chain.pem

### 5) PKCS#7 → PEM

    openssl pkcs7 -in cert.p7b -print_certs -out cert.pem

### 6) PEM → JKS (Java KeyStore)

    keytool -import -alias mycert -file cert.pem -keystore keystore.jks

### 7) JKS → PKCS#12

    keytool -importkeystore -srckeystore keystore.jks -destkeystore keystore.p12 -deststoretype PKCS12
