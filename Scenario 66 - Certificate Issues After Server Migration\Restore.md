# Scenario 66 - Certificate Issues After Server Migration/Restore

## Symptom

Restored server from backup

Certificate present but won't load

"key values mismatch"

"PEM_read_bio:bad decrypt"

Cert works but private key is corrupted/missing

## Diagnostics

### 1) Verify cert and key match (most common)

    openssl x509 -noout -modulus -in cert.crt | openssl md5
    openssl rsa -noout -modulus -in private.key | openssl md5

Hashes must MATCH! If not, wrong key restored.

### 2) Check if key is encrypted

    head -1 private.key

    # "-----BEGIN ENCRYPTED PRIVATE KEY-----" = needs passphrase!
    # "-----BEGIN RSA PRIVATE KEY-----" = unencrypted

### 3) Test key can be read

    openssl rsa -in private.key -check -noout

"RSA key ok" ✅ or error showing corruption

### 4) Check for encoding corruption (binary in text transfer)

    file private.key

Should be "ASCII text" or "PEM"

If "data" → corrupted during transfer (FTP binary/ASCII mode!)

## Common Migration Issues

    ❌ Key transferred in ASCII mode (corrupts binary parts)
    ❌ Wrong key restored (cert/key mismatch)
    ❌ Encrypted key but passphrase lost
    ❌ Line ending conversion (CRLF vs LF) corrupting PEM
    ❌ Permissions wrong after restore
    ❌ Key not backed up at all (only cert!)

## Fix

### 1) Cert/key mismatch. Locate correct key

Search for keys matching the cert

    CERT_MOD=$(openssl x509 -noout -modulus -in cert.crt | openssl md5)
    for key in /backup/keys/*.key; do
      KEY_MOD=$(openssl rsa -noout -modulus -in "$key" 2>/dev/null | openssl md5)
      [ "$CERT_MOD" == "$KEY_MOD" ] && echo "MATCH: $key"
    done

### 2) Encrypted key — decrypt with passphrase

    openssl rsa -in encrypted.key -out decrypted.key

### 3) Line ending corruption — fix it

    dos2unix private.key

Or:

    sed -i 's/\r$//' private.key

### 4) Re-transfer in BINARY mode

scp (always binary) instead of FTP ASCII mode

### 5) If key is truly lost — REISSUE the certificate

A cert without its private key is useless

Generate new key + CSR, get new cert from CA

## Prevention

□ Back up private keys SECURELY (encrypted)

□ Test restores regularly (don't assume backups work!)

□ Use binary-safe transfer (scp, rsync, not FTP ASCII)

□ Document passphrases in a secure vault

□ Store cert+key together in PKCS#12 for atomic backup


