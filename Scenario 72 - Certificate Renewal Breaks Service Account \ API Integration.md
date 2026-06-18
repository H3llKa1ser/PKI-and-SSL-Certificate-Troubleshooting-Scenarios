# Scenario 72 - Certificate Renewal Breaks Service Account / API Integration

## Symptom

Renewed service certificate

Third-party integration suddenly fails

Partner whitelisted your OLD cert fingerprint!

"certificate not recognized" by partner API

B2B integration broken after routine renewal

## Diagnostics

### 1) Check if partner pins/whitelists your cert

Did renewal change the fingerprint they trust?

    openssl x509 -in old-cert.crt -noout -fingerprint -sha256
    openssl x509 -in new-cert.crt -noout -fingerprint -sha256

Different fingerprints = partner's whitelist is now stale

### 2) Check if public key changed

    openssl x509 -in old-cert.crt -pubkey -noout | openssl md5
    openssl x509 -in new-cert.crt -pubkey -noout | openssl md5

If you reused the key, pubkey is same (helps with key pinning)

## The Hidden B2B Trap

Many B2B integrations whitelist YOUR certificate:

    - By full cert fingerprint
    - By public key
    - By exact serial number

Routine renewal changes these → integration breaks!

And you may not control the partner's whitelist update timing.

## Fix

### 1) Reuse the same private key on renewal (key pinning survives)

Generate CSR from existing key

    openssl req -new -key existing-private.key -out renewal.csr

New cert, same public key → pubkey pins still work

### 2) Coordinate renewal with partners in advance

Notify them of the new fingerprint before deploying

Allow overlap window for whitelist updates

### 3) Negotiate CA-based trust instead of cert pinning

Partner trusts your CA, not specific cert

Renewals don't break the integration

### 4) Maintain a renewal calendar with partner dependencies

Document which integrations pin which certs

## Prevention

□ Inventory ALL B2B integrations and what they trust

□ Prefer CA-based trust over cert/key pinning for B2B

□ If pinning required, reuse keys or coordinate rotation

□ Build a partner notification process into renewal workflow


