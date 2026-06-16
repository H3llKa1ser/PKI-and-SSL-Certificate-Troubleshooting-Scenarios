# Scenario 14 - Certificate Pinning Failure

## Symptom

Mobile app stops working after certificate renewal

Error: 

    "Certificate pinning verification failed"

Error: 

    "SSL Pinning Error — peer certificate cannot be authenticated"

App was working fine until cert was renewed/rotated

## Certificate Pinning Definition

Normal TLS:
  
    App trusts ANY cert signed by a trusted CA ✅

Certificate Pinning:
  
    App ONLY trusts a SPECIFIC cert or public key
    └── Even if signed by a trusted CA,
        a different cert = CONNECTION REJECTED ❌

## Diagnostics

### 1) Check if the public key changed after renewal

Old certificate

    openssl x509 -in old-cert.crt -pubkey -noout | openssl sha256

New certificate

    openssl x509 -in new-cert.crt -pubkey -noout | openssl sha256

#### If hashes DIFFER ← Pinned apps will fail!

#### If hashes SAME  ← Key was reused, pinning still works

### 2) Check what's pinned in the app

Android (Inspect APK)

    apktool d your-app.apk
    grep -r "sha256" your-app/

iOS

Inspect the binary or source code

Look for: 

    NSURLSessionDelegate, TrustKit, or SSLPinningMode

## Fix

### Pin the Public Key (not the cert)

#### Pin the PUBLIC KEY instead of the full certificate

#### Public key stays the same when you renew the cert (as long as you reuse the same private key)

Get public key hash for pinning

    openssl x509 -in cert.crt -pubkey -noout | openssl pkey -pubin -outform DER | openssl dgst -sha256 -binary | openssl enc -base64

Use this hash in your mobile app pinning config

### Pin with backup keys

Always configure PRIMARY + BACKUP pin

Primary: Current certificate public key

Backup:  Next certificate public key (pre-generated)

This allows rotation without breaking the app!

### Android Network Security Config

    <!-- res/xml/network_security_config.xml -->
    <network-security-config>
      <domain-config>
        <domain includeSubdomains="true">api.company.com</domain>
        <pin-set expiration="2026-01-01">
          <!-- Primary pin (current cert) -->
          <pin digest="SHA-256">current+cert+hash=</pin>
          <!-- Backup pin (next cert) -->
          <pin digest="SHA-256">next+cert+hash====</pin>
        </pin-set>
      </domain-config>
    </network-security-config>
