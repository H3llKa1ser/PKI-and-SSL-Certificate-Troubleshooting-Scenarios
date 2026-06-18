# Command Cheatsheet

# ── INSPECTION ──
    openssl x509 -in cert.crt -text -noout              # Read certificate
    openssl x509 -in cert.crt -noout -dates             # Check expiry
    openssl x509 -in cert.crt -noout -subject -issuer   # Subject & issuer
    openssl x509 -in cert.crt -noout -ext subjectAltName # Check SANs

# ── LIVE CONNECTION ──
    openssl s_client -connect host:443                  # Test connection
    openssl s_client -connect host:443 -servername host # Test with SNI
    openssl s_client -connect host:443 -showcerts       # Full chain
    openssl s_client -connect host:443 -status          # OCSP stapling

# ── VERIFICATION ──
    openssl verify -CAfile ca.crt cert.crt              # Verify against CA
    openssl verify -untrusted intermediate.crt cert.crt # With intermediate

# ── CERT/KEY MATCH (must produce same hash!) ──
    openssl x509 -noout -modulus -in cert.crt | openssl md5
    openssl rsa  -noout -modulus -in key.key  | openssl md5

# ── EXPIRY ONE-LINER ──
    echo | openssl s_client -connect host:443 2>/dev/null | openssl x509 -noout -dates

# ── FORMAT CONVERSION ──
    openssl x509 -in c.pem -outform DER -out c.der      # PEM → DER
    openssl x509 -in c.der -inform DER -out c.pem       # DER → PEM
    openssl pkcs12 -in b.pfx -nodes -out c.pem          # PKCS12 → PEM

# ── EXTERNAL TOOLS ──
    # SSL Labs:    https://www.ssllabs.com/ssltest/
    # CT logs:     https://crt.sh/?q=yourdomain.com
    # Full scan:   ./testssl.sh https://host
