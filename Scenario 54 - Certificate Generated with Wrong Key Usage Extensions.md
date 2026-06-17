# Scenario 54 - Certificate Generated with Wrong Key Usage Extensions.md

## Symptom

Cert installs but specific functions fail

"unsupported certificate purpose"

Cert works for web but not for client auth

"key usage does not include digital signature"

Encryption works but signing fails (or vice versa)

## Diagnostics

### 1) Check Key Usage and Extended Key Usage

    openssl x509 -in cert.crt -noout -text | grep -A3 "Key Usage"

What you need for different purposes:

    # TLS Server:    Digital Signature, Key Encipherment
    #                EKU: TLS Web Server Authentication
    # TLS Client:    Digital Signature
    #                EKU: TLS Web Client Authentication
    # Code Signing:  Digital Signature
    #                EKU: Code Signing
    # Email (S/MIME):Digital Signature, Key Encipherment
    #                EKU: E-mail Protection
    # CA Cert:       Certificate Sign, CRL Sign

### 2) Verify cert for specific purpose

    openssl verify -purpose sslserver -CAfile ca.crt cert.crt
    openssl verify -purpose sslclient -CAfile ca.crt cert.crt

## Fix

### Generate cert with correct extensions

Create an extensions config file

    cat > cert-ext.cnf << 'EOF'
    [v3_req]
    basicConstraints = CA:FALSE
    keyUsage = digitalSignature, keyEncipherment
    extendedKeyUsage = serverAuth, clientAuth    # Both server AND client!
    subjectAltName = @alt_names
    
    [alt_names]
    DNS.1 = service.company.com
    DNS.2 = service
    EOF

Sign with the correct extensions

    openssl x509 -req -in service.csr -CA ca.crt -CAkey ca.key -out service.crt -days 365 -extfile cert-ext.cnf -extensions v3_req

Verify the extensions were applied

    openssl x509 -in service.crt -noout -text | grep -A3 "Key Usage"
