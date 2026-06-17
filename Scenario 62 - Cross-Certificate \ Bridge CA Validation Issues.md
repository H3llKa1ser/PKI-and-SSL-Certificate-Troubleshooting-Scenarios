# Scenario 62 - Cross-Certificate / Bridge CA Validation Issues

## Symptom

Federated PKI environments (government, large enterprise)

Cert validates in one org but not the partner org

"path building failed" despite valid certs

Bridge CA trust not establishing

Cross-certified paths not discovered

## Diagnostics

### 1) Understand the trust topology

Bridge CA connects multiple separate PKIs:

Org A Root ←→ Bridge CA ←→ Org B Root

A cert from Org A must build a path THROUGH the bridge to Org B

### 2) Check for cross-certificates

    openssl x509 -in cert.crt -noout -text | grep -A5 "Authority Information Access"

Look for caIssuers URLs pointing to cross-certs

### 3) Test path building with all intermediates

    openssl verify -CAfile bridge-ca.crt -untrusted "cross-cert-a.crt" -untrusted "cross-cert-b.crt" -untrusted "intermediate.crt" partner-cert.crt

### 4) Check policy constraints (often the issue!)

    openssl x509 -in cross-cert.crt -noout -text | grep -A5 "Certificate Policies\|Policy Constraints"

## Why Bridge CAs are complex

Bridge PKI uses cross-certificates:

    - Org A issues a cert FOR Org B's CA
    - Org B issues a cert FOR Org A's CA
    - This creates a "bridge" of mutual trust

Validation must build a path through these cross-certs
Policy mappings must align between organizations
This is genuinely one of the hardest PKI scenarios!

## Fix

### 1) Provide all cross-certificates to the validator

The client needs every cross-cert to build the path

### 2) Ensure Authority Information Access (AIA) is correct

AIA caIssuers must point to retrievable cross-certs

Enables automatic path discovery (AIA chasing)

### 3) Verify policy mappings

Each org's policies must map correctly across the bridge

certificatePolicies + policyMappings must align

### 4) Use a validator that supports full path discovery

Not all libraries do AIA chasing — some need manual cert provision

OpenSSL: use -CAfile and -untrusted with ALL relevant certs

### 5) For Windows — ensure cross-certs are in NTAuth/AIA stores

    certutil -dspublish -f crosscert.crt CrossCA
