# Scenario 24 - Intermediate CA Certificate Expiring

## Symptom

Your server cert is valid for another year ✅

But suddenly EVERYTHING breaks!

Error: 

    "certificate has expired"

But you JUST renewed your server cert?!

## Diagnostics

### 1) Check the ENTIRE chain's expiry, not just leaf

    openssl s_client -connect example.com:443 -showcerts 2>/dev/null | awk '/BEGIN CERT/,/END CERT/' > chain.pem

### 2) Check each certificate in the chain

    csplit -z -f cert- chain.pem '/BEGIN CERTIFICATE/' '{*}'
    for cert in cert-*; do
      echo "=== $cert ==="
      openssl x509 -in $cert -noout -subject -dates
    done

#### Output reveals the truth:

    === cert-00 ===   (Leaf)
    subject=CN=example.com
    notAfter=Jan 01 2026   ✅ Valid
    
    === cert-01 ===   (Intermediate)
    subject=CN=Intermediate CA
    notAfter=Jun 15 2026   ❌ EXPIRES SOON / EXPIRED!

## Fix

### 1) Download the NEW intermediate from your CA

CAs publish updated intermediates when they roll them over

    wget https://yourca.com/intermediate-new.crt

### 2) Update your fullchain with new intermediate

    cat server.crt intermediate-new.crt root.crt > fullchain.crt

### 3) Reload web server

    nginx -t && systemctl reload nginx

### 4) Verify the new chain

    openssl s_client -connect example.com:443 -showcerts 2>/dev/null | grep "issuer\|notAfter"

## Prevention

□ Monitor the ENTIRE chain expiry, not just the leaf cert!

□ Subscribe to your CA's notifications about intermediate changes

□ Re-download intermediates when you renew leaf certs

□ Most CAs roll intermediates — stay informed!
