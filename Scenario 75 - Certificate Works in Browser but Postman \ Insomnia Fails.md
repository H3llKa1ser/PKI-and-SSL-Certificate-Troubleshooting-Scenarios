# Scenario 75 - Certificate Works in Browser but Postman / Insomnia Fails

## Symptom

API works in browser ✅

Postman/Insomnia: "SSL Error: unable to verify"

"self signed certificate in certificate chain"

API testing tools reject certs browsers accept

## Diagnostics

### 1) Why the difference?

Browsers: use OS trust store + their own

Postman: uses its OWN cert handling, may not have your CA

Some tools don't follow AIA to fetch missing intermediates

### 2) Check if intermediate is being served

    echo | openssl s_client -connect api.host:443 -showcerts 2>/dev/null | grep -c "BEGIN CERTIFICATE"

Browser might fetch missing intermediate via AIA

Postman might NOT → fails!

### 3) Check AIA (browsers use this, tools often don't)

    openssl x509 -in cert.crt -noout -text | grep "CA Issuers"

## Fix

### 1) Serve the complete chain (don't rely on AIA fetching!)

This fixes browsers AND tools

    cat server.crt intermediate.crt > fullchain.crt

Configure server to use fullchain

### 2) Postman. Add CA certificate

Settings → Certificates → CA Certificates → add your CA cert

### 3) Postman — disable SSL verification (testing only!)

Settings → General → SSL certificate verification → OFF

⚠️ Only for testing, NEVER assume this is the "fix"

### 4) Insomnia. Add client cert / CA

Preferences → similar CA cert configuration

####  If browsers work but tools fail, it's almost ALWAYS an incomplete chain — browsers paper over it with AIA fetching, tools don't!
