# Scenario 34 - ECDSA vs RSA Certificate Incompatibility

## Symptom

Modern clients work ✅ but legacy systems fail ❌

"No shared cipher"

"Handshake failure"

Old payment terminals / IoT devices can't connect

ECDSA cert deployed but some clients reject it

## Diagnostics

### 1) Identify your cert's key type

    openssl x509 -in cert.crt -noout -text | grep "Public Key Algorithm"

"id-ecPublicKey" = ECDSA

"rsaEncryption"  = RSA

### 2) Check what the failing client supports

Old clients may only support RSA

    openssl s_client -connect host:443 -cipher 'ECDHE-ECDSA' 2>&1 | grep -i "error\|cipher"

### 3) Test client capabilities

    nmap --script ssl-enum-ciphers -p 443 host

### 4) Check which cipher was negotiated

    openssl s_client -connect host:443 2>/dev/null | grep "Cipher"

## RSA vs ECDSA comparison

    🔢 RSA:
       ✅ Universal compatibility (works everywhere)
       ❌ Larger keys (2048/4096 bit)
       ❌ Slower handshake
       ✅ Older clients support it
    
    🔢 ECDSA:
       ✅ Faster, smaller keys (256-bit ECDSA ≈ 3072-bit RSA)
       ✅ Better performance
       ❌ Older clients may not support it
       ❌ Some legacy systems reject it

## Fix

###1) Serve both certificates (Dual-Cert)

Nginx

    # Nginx can serve BOTH ECDSA and RSA!
    # Modern clients get ECDSA, old clients get RSA
    
    server {
        listen 443 ssl;
    
        # ECDSA certificate (preferred for modern clients)
        ssl_certificate     /etc/ssl/ecdsa.crt;
        ssl_certificate_key /etc/ssl/ecdsa.key;
    
        # RSA certificate (fallback for legacy clients)
        ssl_certificate     /etc/ssl/rsa.crt;
        ssl_certificate_key /etc/ssl/rsa.key;
    
        # Nginx auto-selects based on client capabilities! ✅
    }

Apache

    # Apache 2.4.8+ also supports dual certs:
    SSLCertificateFile /etc/ssl/ecdsa.crt
    SSLCertificateKeyFile /etc/ssl/ecdsa.key
    SSLCertificateFile /etc/ssl/rsa.crt
    SSLCertificateKeyFile /etc/ssl/rsa.key

