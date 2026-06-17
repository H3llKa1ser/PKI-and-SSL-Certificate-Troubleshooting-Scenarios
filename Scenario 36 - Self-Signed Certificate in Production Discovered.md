# Scenario 36 - Self-Signed Certificate in Production Discovered

## Symptom

Security audit flags self-signed certificate

Browser: "Certificate is self-signed"

ERR_CERT_AUTHORITY_INVALID

Internal service quietly using self-signed cert for months!

## Diagnostics

### 1) Identify if cert is self-signed

    openssl x509 -in cert.crt -noout -subject -issuer

If Subject == Issuer → SELF-SIGNED! ⚠️

subject=CN=internal-api.company.com

issuer=CN=internal-api.company.com    ← SAME = self-signed!

### 2) Find all self-signed certs in your environment

    for host in $(cat hostlist.txt); do
      SUBJ=$(echo | openssl s_client -connect $host:443 2>/dev/null \
        | openssl x509 -noout -subject)
      ISS=$(echo | openssl s_client -connect $host:443 2>/dev/null \
        | openssl x509 -noout -issuer)
      if [ "$SUBJ" == "${ISS/issuer/subject}" ]; then
        echo "⚠️ SELF-SIGNED: $host"
      fi
    done

## Why Self-Signed is dangerous

    ❌ No third-party validation of identity
    ❌ Vulnerable to man-in-the-middle attacks
    ❌ Trains users to ignore certificate warnings (BAD habit!)
    ❌ Can't be revoked through normal channels
    ❌ Fails compliance audits (PCI-DSS, SOC2, etc.)

## Fix

### 1) Replace with proper CA-signed cert

For internal services — use your internal CA:

    openssl req -new -key service.key -out service.csr -subj "/CN=internal-api.company.com"

Sign with internal CA

    openssl x509 -req -in service.csr -CA internal-ca.crt -CAkey internal-ca.key -out service.crt -days 365 -extfile <(echo "subjectAltName=DNS:internal-api.company.com")

### 2) For public services, use Let's Encrypt or commercial CA

    certbot certonly --nginx -d api.company.com

### 3) Distribute internal CA to all clients

So internal CA-signed certs are trusted everywhere

