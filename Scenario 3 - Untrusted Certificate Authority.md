# Scenario 3 - Untrusted Certificate Authority

## Symptom

Browser:

    "Your connection is not private" — ERR_CERT_AUTHORITY_INVALID

curl:

    SSL certificate problem: unable to get local issuer certificate

Java app:

    sun.security.validator.ValidatorException: PKIX path building failed

## Diagnostics

### 1) Check full certificate chain

    openssl s_client -connect internal.company.com:443 -showcerts

### 2) Verify chain manually

    openssl verify -CAfile root-ca.crt -untrusted intermediate-ca.crt server.crt

### 3) Check if Root CA is in system trust store

Linux

    ls /etc/ssl/certs/ | grep company

RHEL/CentOS

    certutil -L -d /etc/pki/nssdb

## Common Causes

    ❌ Internal/private CA not added to trust store
    ❌ Incomplete certificate chain (missing intermediate)
    ❌ Root CA cert distributed incorrectly
    ❌ Self-signed certificate in production
    ❌ Wrong CA bundle installed on server

## Fix

### Add CA to System Trust Store

Ubuntu/Debian

    cp company-root-ca.crt /usr/local/share/ca-certificates/
    update-ca-certificates

RHEL/CentOS

    cp company-root-ca.crt /etc/pki/ca-trust/source/anchors/
    update-ca-trust

Windows (PowerShell)

    Import-Certificate -FilePath "company-root-ca.crt" -CertStoreLocation Cert:\LocalMachine\Root

MacOS

    sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain company-root-ca.crt

### Fix incomplete chain on Nginx

nginx conf

    ssl_certificate /etc/ssl/server.crt;            # Server cert only ❌

Change to:
    
    ssl_certificate /etc/ssl/fullchain.crt;         # Server + Intermediate ✅
    ssl_certificate_key /etc/ssl/private.key;

### Fix Incomplete Chain on Apache

    SSLCertificateFile    /etc/ssl/server.crt
    SSLCertificateKeyFile /etc/ssl/private.key
    SSLCertificateChainFile /etc/ssl/intermediate.crt   ← Add this!

