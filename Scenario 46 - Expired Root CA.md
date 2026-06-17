# Scenario 46 - Expired Root CA.md

## Symptom

EVERYTHING breaks simultaneously across the organization

ALL certificates suddenly invalid

"certificate has expired" on every internal service

Even valid leaf/intermediate certs fail!

Total infrastructure outage

## Diagnostics

### 1) Confirm root CA expiry

    openssl x509 -in root-ca.crt -noout -dates -subject

### 2) Check what is in client trust stores

The expired root is still being used to validate!

    ls -la /etc/ssl/certs/ | grep your-root

### 3) Identify the affected root

    openssl s_client -connect internal-service:443 -showcerts 2>/dev/null | awk '/BEGIN/,/END/' | tail -n +X | openssl x509 -noout -dates

## Real World Example

    The AddTrust External CA Root expired May 30, 2020
    Result: Massive outages because:
      - Old devices still chained to this root
      - Services that hardcoded the old chain failed
      - IoT devices couldn't update their trust stores

Lesson: Root CA expiry is a TIME BOMB you must plan for!

## Fix

### 1) Deploy new root CA to all trust stores BEFORE old expires

#### (This must be planned MONTHS in advance!)

Add new root to system trust store

    cp new-root-ca.crt /usr/local/share/ca-certificates/
    update-ca-certificates

### 2) Cross-sign certificates (bridge old and new)

New root cross-signs with old root during transition

Allows both chains to validate during migration

### 3) Update certificate chains to use new root

    cat server.crt intermediate.crt new-root.crt > fullchain.crt

### 4) For emergency — use alternate chain

Many certs can chain to MULTIPLE roots

Switch the served chain to a non-expired root

## Prevention

□ Monitor root CA expiry YEARS in advance

□ Root CAs typically last 20-25 years — but they DO expire!

□ Plan root rotation 2-3 years before expiry

□ Use cross-signing for smooth transitions

□ Maintain an inventory of ALL roots in use

□ Test root rotation in staging FIRST

□ Document which services chain to which roots
