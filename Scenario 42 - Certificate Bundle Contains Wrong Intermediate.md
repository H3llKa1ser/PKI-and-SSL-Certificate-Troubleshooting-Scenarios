# Scenario 42 - Certificate Bundle Contains Wrong Intermediate

## Symptom

Chain looks complete but verification fails

"unable to get local issuer certificate"

The intermediate doesn't actually match the leaf!

CA changed intermediates but you used the old one

## Diagnostics

### 1) Check leaf cert's issuer

    openssl x509 -in server.crt -noout -issuer

### 2) Check your intermediate's subject

Must MATCH issuer above!

    openssl x509 -in intermediate.crt -noout -subject

### 3) Verify the AKI/SKI link

Leaf's Authority Key Identifier

    openssl x509 -in server.crt -noout -text | grep -A1 "Authority Key Identifier"

Intermediate's Subject Key Identifier

    openssl x509 -in intermediate.crt -noout -text | grep -A1 "Subject Key Identifier"

#### These MUST match! (AKI of leaf = SKI of intermediate)

### 4) Full chain verification

    openssl verify -CAfile root.crt -untrusted intermediate.crt server.crt

## Fix

### 1) Download the correct intermediate

Get it from the leaf cert's issuer URL

    openssl x509 -in server.crt -noout -text | grep "CA Issuers"

#### CA Issuers - URI:http://cacerts.digicert.com/correct-intermediate.crt

Download it

    wget http://cacerts.digicert.com/correct-intermediate.crt -O intermediate.crt

Convert if needed (often DER)

    openssl x509 -in intermediate.crt -inform DER -out intermediate.pem

### 2) Rebuild chain with correct intermediate

    cat server.crt intermediate.pem > fullchain.crt

### 3) Verify it now works

    openssl verify -untrusted intermediate.pem server.crt

