# Scenario 33 - VPN Certificate Authentication Failure

## Symptom

VPN client can't connect

"Certificate validation failure"

OpenVPN: "VERIFY ERROR: depth=0, error=unable to get local issuer"

IKEv2: "AUTHENTICATION_FAILED"

Users randomly disconnected and can't reconnect

## Diagnostics

### 1) Check VPN certificate validity

    openssl x509 -in client.crt -noout -dates -subject

### 2) Verify cert was issued by VPN's CA

    openssl verify -CAfile vpn-ca.crt client.crt

### 3) Check Extended Key Usage (CRITICAL for VPN)

    openssl x509 -in client.crt -noout -text | grep -A2 "Extended Key Usage"

For VPN you need:

    # Client cert: TLS Web Client Authentication
    # Server cert: TLS Web Server Authentication
    # IKEv2:       may need "IP security IKE intermediate"

### 4) Check OpenVPN logs

    tail -f /var/log/openvpn/openvpn.log | grep -i "verify\|cert"

### 5) Test the full chain

    openssl verify -CAfile vpn-ca.crt -purpose sslclient client.crt

## Common Issues

    ❌ Wrong Extended Key Usage
       OpenVPN/strongSwan are strict about EKU!
    
    ❌ Certificate revoked but CRL not updated on server
    
    ❌ Missing "remote-cert-tls server" verification
    
    ❌ Client cert and server cert from different CAs
    
    ❌ tls-crypt/tls-auth key mismatch (separate from certs!)

## Fix 

### 1) OpenVPN Server config

server.conf

    ca /etc/openvpn/ca.crt
    cert /etc/openvpn/server.crt
    key /etc/openvpn/server.key

Verify client certs against CRL

    crl-verify /etc/openvpn/crl.pem

Require client cert to have client EKU

    remote-cert-tls client

Client config (client.ovpn)

    remote-cert-tls server     # Verify server has server EKU
    verify-x509-name "server.company.com" name

### 2) Generate cert with correct EKU

Client cert with proper EKU

    openssl req -new -key client.key -out client.csr

Sign with client EKU extension

    openssl x509 -req -in client.csr -CA vpn-ca.crt -CAkey vpn-ca.key -out client.crt -days 365 -extfile <(echo "extendedKeyUsage=clientAuth")
  
