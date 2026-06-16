# Scenario 12 - Wildcard Certificate Problems

## Symptom

    *.company.com certificate installed
    api.company.com       ✅ Works
    www.company.com       ✅ Works
    mail.company.com      ✅ Works
    deep.api.company.com  ❌ FAILS!  ← Wildcard doesn't cover this!
    company.com           ❌ FAILS!  ← Bare domain not covered!

## Diagnostics

### 1) Inspect what the wildcard covers

    openssl x509 -in wildcard.crt -noout -text | grep -A5 "Subject Alternative Name"

### 2) Test specific subdomains

    curl -v https://deep.api.company.com 2>&1 | grep "SSL"

## Wildcard Coverage Rules

Certificate: *.company.com
    
    ✅ Covered:
       api.company.com
       www.company.com
       mail.company.com
       anything.company.com
    
    ❌ NOT Covered:
       company.com              ← bare domain (needs explicit SAN)
       deep.api.company.com     ← two levels deep
       *.api.company.com        ← nested wildcard (not allowed by browsers)

## Fix

### Multi-SAN certificate

Request cert with explicit SANs for all cases

    openssl req -new -key private.key -out request.csr -config san.cnf

san.cnf

    [req]
    distinguished_name = req_distinguished_name
    req_extensions = v3_req
    prompt = no
    
    [req_distinguished_name]
    CN = company.com
    
    [v3_req]
    subjectAltName = @alt_names
    
    [alt_names]
    DNS.1 = company.com                  ← bare domain
    DNS.2 = *.company.com                ← first level wildcard
    DNS.3 = *.api.company.com            ← nested wildcard
    DNS.4 = deep.api.company.com         ← explicit deep subdomain

