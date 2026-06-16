# Scenario 7 - Private Key Compromised

## Symptom

Security Team reports:

    Private key found in public GitHub repo!

OR: 

    Unauthorized access detected using a service certificate

OR: 

    Certificate private key accidentally logged

In short, this is a security incident!

## Incident Response Steps

### 1) Revoke the certificate immediately

Log into your CA portal

Find the certificate by serial number

Click REVOKE — reason: "Key Compromise"

### 2) Issue a NEW certificate with a NEW key pair

New key

    openssl genrsa -out new-private.key 2048

Create CSR

    openssl req -new -key new-private.key -out new.csr

Submit CSR to CA for new certificate

### 3) Deploy the new certificate everywhere

All servers using the old cert

All services configured with old cert

All clients that were given the old cert

### 4) Verify revocation is working

    openssl ocsp -issuer intermediate-ca.crt -cert compromised.crt -url http://ocsp.yourca.com -resp_text

### 5) Investigate breach

How was the key exposed?

Was it exploited?

What data was potentially accessed?

### 6) Rotate ALL related credentials

API keys, passwords used with that service

Any secrets the compromised service had access to

## Prevention

□ NEVER commit private keys to Git (use .gitignore!)

□ NEVER log private key material

□ Store private keys in HSMs or secret managers (Vault, AWS Secrets Manager)

□ Set up secret scanning in your CI/CD pipeline (GitHub has this built-in!)

□ Use short-lived certificates — limits exposure window

□ Audit who has access to private keys regularly
