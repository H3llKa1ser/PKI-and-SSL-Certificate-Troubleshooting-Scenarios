# Scenario 25 - Email/S/MIME Certificate Problems

## Symptom

Encrypted emails cannot be read

"This message cannot be decrypted"

Digital signatures show as invalid/untrusted

Outlook: "There was an error trying to verify the signature"

## Diagnostics

### 1) Check the S/MIME certificate

    openssl x509 -in smime-cert.crt -noout -text | grep -A5 "Key Usage\|Extended Key Usage"

For S/MIME you NEED:

Key Usage: Digital Signature, Key Encipherment

Extended Key Usage: E-mail Protection ✅

### 2) Check the email address matches

    openssl x509 -in smime-cert.crt -noout -text | grep -A1 "Subject Alternative Name"
    
Must contain: email:user@company.com

### 3) Verify the cert chain

    openssl verify -CAfile ca-chain.crt smime-cert.crt

### 4) Check certificate hasn't expired

    openssl x509 -in smime-cert.crt -noout -dates

## Common S/MIME issues

    ❌ Recipient doesn't have your public certificate
       (You can't encrypt TO someone without their public key!)
    
    ❌ Email address in cert doesn't match sender address
    
    ❌ Private key lost — can't decrypt old emails! (CRITICAL)
    
    ❌ Certificate not published to directory (GAL/LDAP)
    
    ❌ Wrong Extended Key Usage (missing E-mail Protection)

## Fix

### 1) Exchange public certs before encrypting

Send a SIGNED email first (attaches your public cert)

Recipient does the same — now you can encrypt to each other

### 2) Key archival for decryption (CRITICAL)

 Always archive S/MIME private keys

If lost, encrypted emails are GONE FOREVER!

Use enterprise key escrow / archival

### 3) Export/Import certificate properly

Export with private key (PKCS#12)

    openssl pkcs12 -export -in smime-cert.crt -inkey private.key -out smime.p12 -name "My S/MIME Cert"

Import into Outlook:

    File → Options → Trust Center → Email Security → Import/Export
