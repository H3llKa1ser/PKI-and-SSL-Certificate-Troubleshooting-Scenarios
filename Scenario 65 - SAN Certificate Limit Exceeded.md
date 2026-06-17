# Scenario 65 - SAN Certificate Limit Exceeded.md

## Symptom

Trying to add the 101st domain to a SAN cert

CA rejects: "too many names"

Certificate becomes unwieldy / huge

Performance degrades with hundreds of SANs

Managing one giant cert becomes a nightmare

## Diagnostics

### 1) Count SANs in current cert

    openssl x509 -in cert.crt -noout -text | grep -A1 "Subject Alternative Name" | tr ',' '\n' | grep -c "DNS:"

Most CAs limit to 100-250 SANs per cert

Let's Encrypt: 100 names max

Large SAN certs = large handshakes = slower

### 2) Check the actual handshake impact

    openssl s_client -connect host:443 -msg 2>&1 | grep -i "certificate" | head

## Fix

### 1) Use a wildcard instead of many SANs

Instead of: app1.x.com, app2.x.com, app3.x.com...

Use: *.x.com (one wildcard covers all!)

### 2) Split into multiple certificates

Group domains logically across several certs

    # cert1: customer-facing domains
    # cert2: internal tools
    # cert3: API endpoints

### 3) Use SNI with per-domain certs

Each domain gets its OWN cert

Server selects via SNI — no giant SAN list needed!

### 4) For many subdomains, wildcard + bare domain

*.x.com + x.com covers nearly everything

### 5) Consider a private CA for internal sprawl

Issue individual certs freely without CA limits/costs
