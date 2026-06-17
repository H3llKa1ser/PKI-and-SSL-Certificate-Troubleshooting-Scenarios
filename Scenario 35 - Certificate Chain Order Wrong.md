# Scenario 35 - Certificate Chain Order Wrong

## Symptom

Chain has all the right certs but STILL fails

"unable to verify the first certificate"

Some clients work, others don't

SSL Labs shows "Chain issues: Incorrect order"

## Diagnostics

### 1) Examine the order in your chain file

    openssl crl2pkcs7 -nocrl -certfile fullchain.crt | openssl pkcs7 -print_certs -noout | grep "subject\|issuer"

    # CORRECT order (leaf first, root last):
    # 1. subject=CN=yoursite.com         (LEAF — your cert)
    #    issuer=CN=Intermediate CA
    # 2. subject=CN=Intermediate CA      (INTERMEDIATE)
    #    issuer=CN=Root CA
    # 3. subject=CN=Root CA              (ROOT — optional)
    
    # WRONG order example:
    # Root cert first, leaf last ❌
    # Intermediate before leaf ❌

## The Golden Rule of Chain Order

    ✅ CORRECT ORDER (bottom-up):
    ┌─────────────────────────┐
    │ 1. Your Server Cert     │ ← Leaf (FIRST)
    ├─────────────────────────┤
    │ 2. Intermediate CA      │ ← Middle
    ├─────────────────────────┤
    │ 3. Root CA (optional)   │ ← Root (LAST)
    └─────────────────────────┘
    
Each cert's ISSUER must be the NEXT cert's SUBJECT!

## Fix

### 1) Rebuild the chain in CORRECT order

    cat server.crt intermediate.crt root.crt > fullchain.crt
    #   ^leaf       ^intermediate    ^root

### 2) Verify the order is correct

    openssl verify -verbose -CAfile root.crt -untrusted intermediate.crt server.crt

Output: server.crt: OK ✅

Quick visual verification of order

    while openssl x509 -noout -subject -issuer; do :; done < fullchain.crt
