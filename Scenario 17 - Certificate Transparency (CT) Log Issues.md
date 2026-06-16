# Scenario 17 - Certificate Transparency (CT) Log Issues

## Symptom

Chrome browser shows:

    "This site is missing a valid, trusted certificate transparency log"

    ERR_CERTIFICATE_TRANSPARENCY_REQUIRED

Certificate is valid but browser rejects it!

## Certificate Transparency Definition

Since 2018, ALL publicly trusted certificates MUST be logged in public Certificate Transparency (CT) logs.

This means:

    ✅ Every cert issued is publicly visible and auditable
    ✅ You can detect unauthorized certs issued for your domain
    ✅ Browsers verify CT log inclusion (SCTs)
    ❌ Old certs without SCTs = browser rejection!

## Diagnostics

### 1) Check if cert has SCTs (Signed Certificate Timestamps)

    openssl x509 -in server.crt -noout -text | grep -A5 "CT Precertificate SCTs"

#### Good output (has SCTs):

    CT Precertificate SCTs:
      Signed Certificate Timestamp:
        Version   : v1 (0x0)
        Log ID    : A4:B9:09:90... ✅

#### Bad output (no SCTs):

    Nothing here ❌ ← Browser will reject!

### 2) Check CT logs online

    https://crt.sh/?q=yourdomain.com

Shows all known certs for your domain in CT logs

### 3) Check for unauthorized certs

    curl "https://crt.sh/?q=%.yourdomain.com&output=json" | jq '.[].name_value' | sort -u

## Fix

### 1) Reissue certificate from a modern CA

Modern CAs (DigiCert, Let's Encrypt, etc.) automatically submit to CT logs and embed SCTs in the certificate

### 2) Use TLS extension for SCT delivery

Server sends SCTs via TLS extension (OCSP stapling)
   
Configure in your web server

### 3) Monitor crt.sh for unauthorized certs

Set up alerts when unexpected certs appear for your domain
   
Tools: Facebook CT Monitor, Google CT Monitor

### Bash script for monitoring unauthorized certs

# Script to monitor CT logs for your domain

    #!/bin/bash
    DOMAIN="yourdomain.com"
    
    curl -s "https://crt.sh/?q=%.${DOMAIN}&output=json" \
      | jq -r '.[] | "\(.not_before) | \(.name_value) | \(.issuer_name)"' \
      | sort \
      | grep -v "company-approved-ca"   # Alert on unknown CAs!

  
