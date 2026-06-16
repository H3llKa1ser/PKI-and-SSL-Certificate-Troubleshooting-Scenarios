# Scenario 2 - Certificate Name Mismatch

## Symptom

Browser shows:

    SSL_ERROR_BAD_CERT_DOMAIN

Error:

    "The certificate is for a different website"

curl output

    SSL: no alternative certificate subject name matches target host name

## Diagnostics

### 1) What domain the cert is issued for?

    echo | openssl s_client -connect yoursite.com:443 2>/dev/null | openssl x509 -noout -text | grep -A1 "Subject Alternative Name"

### 2) Check Common Name

    echo | openssl s_client -connect yoursite.com:443 2>/dev/null | openssl x509 -noout -subject

## Potential causes

    ❌ Cert issued for www.example.com but accessing example.com
    ❌ Cert issued for example.com but accessing api.example.com
    ❌ Wildcard *.example.com but accessing sub.sub.example.com
    ❌ Internal hostname but cert has external FQDN
    ❌ IP address access but cert only has domain names

## Fix

### 1) Request a new certificate with ALL requied SANs

    openssl req -new -key private.key -out new.csr -config san.cnf

san.cnf contents

    [req]
    distinguished_name = req_distinguished_name
    req_extensions = v3_req
    
    [req_distinguished_name]
    CN = yoursite.com
    
    [v3_req]
    subjectAltName = @alt_names
    
    [alt_names]
    DNS.1 = yoursite.com          ← bare domain
    DNS.2 = www.yoursite.com      ← www
    DNS.3 = api.yoursite.com      ← api subdomain
    IP.1  = 192.168.1.100         ← IP if needed

## Prevention

□ Always list ALL domain names in the SAN field

□ Include both bare domain AND www

□ Include internal hostnames if accessed internally

□ Test with curl before going live
