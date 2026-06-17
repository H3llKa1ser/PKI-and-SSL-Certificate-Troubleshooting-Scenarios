# Scenario 52 - Certificate Pinning in Mobile App After CA Migration.md

## Symptom

Company switches from DigiCert to Let's Encrypt

ALL mobile app users suddenly can't connect!

Web works fine ✅ but mobile app fails ❌

"SSL handshake failed" in app only

App update required to fix — but users haven't updated!

## Diagnostics

### 1) Check what the app pins

Decompile and inspect (Android)

    apktool d app.apk
    grep -r "sha256/\|pin-sha256\|certificatePinner" app/

### 2) Compare pinned values with new cert

Get new cert's pin

    openssl x509 -in new-cert.crt -pubkey -noout | openssl pkey -pubin -outform DER | openssl dgst -sha256 -binary | openssl enc -base64

If pinned value ≠ new cert's pin → app will reject!

### 3) Determine pin type

Leaf cert pin (breaks on EVERY renewal!)

Intermediate CA pin (breaks on CA change)

Root CA pin (most stable)

## Why this is a disaster

    Mobile apps can't be force-updated instantly!
    If you pin and change CA without a backup pin:
      → Users with old app version are PERMANENTLY locked out
      → Until they manually update the app
      → Could be days/weeks for many users
      → Business-critical outage!

## Fix

### 1) Emergency. Add backup pins for both CAs (Android)

Then push app update.

    val certificatePinner = CertificatePinner.Builder()
        .add("api.company.com", "sha256/OLD_DIGICERT_PIN=")    // Old
        .add("api.company.com", "sha256/NEW_LETSENCRYPT_PIN=") // New
        .add("api.company.com", "sha256/BACKUP_FUTURE_PIN=")   // Future backup
        .build()

### 2) Roll back to old CA temporarily

Reissue cert from the original (pinned) CA

Buys time while users update the app

### 3) Server-side — serve a chain that satisfies old pin

If you pinned the intermediate, find a cert path through it

## Prevention

□ NEVER pin a single certificate without backup pins

□ Pin the PUBLIC KEY, not the certificate

□ Always include 2-3 backup pins (future certs/CAs)

□ Pin to intermediate or root, not leaf (more stable)

□ Pre-generate next key pair and pin it in advance

□ Have a remote "kill switch" to disable pinning in emergencies

□ Test CA migration in staging with pinned builds FIRST

