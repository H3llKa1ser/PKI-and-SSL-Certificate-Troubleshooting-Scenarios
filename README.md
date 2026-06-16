# PKI-and-SSL-Certificate-Troubleshooting-Scenarios

Here you will find playbooks that will assist you with troubleshooting your PKI and SSL certificate infrastructure.

# Troubleshooting Decision Tree

    TLS/Certificate Error Reported
             │
             ▼
    Is the cert EXPIRED?
       Yes ──► Renew certificate immediately
       No  ──► Continue
             │
             ▼
    Does the DOMAIN NAME match?
       No  ──► Reissue cert with correct SANs
       Yes ──► Continue
             │
             ▼
    Is the CA TRUSTED?
       No  ──► Add CA to trust store OR fix cert chain
       Yes ──► Continue
             │
             ▼
    Is it an mTLS issue?
       Yes ──► Check client cert, CA trust, key usage
       No  ──► Continue
             │
             ▼
    Is the CHAIN complete?
       No  ──► Build fullchain.crt with all intermediates
       Yes ──► Continue
             │
             ▼
    TLS version/cipher mismatch?
       Yes ──► Update TLS config on server or client
       No  ──► Continue
             │
             ▼
    Check logs for specific error codes
    and escalate with full diagnostic output

# Golden rules of Certificate Troubleshooting

    1. 🔍 ALWAYS check expiry first — it's the most common issue
    2. 🔗 ALWAYS verify the full chain — not just the server cert
    3. 🏷️  ALWAYS check SANs — CN alone is not enough (deprecated)
    4. 🔑 ALWAYS verify cert/key pair match — mismatches are common
    5. 📋 ALWAYS check key usage — client auth vs server auth matters
    6. 🌐 USE SSL Labs — it catches issues you'll miss manually
    7. 📝 ALWAYS check logs — the exact error tells you exactly what's wrong
    8. 🤖 AUTOMATE renewals — most issues come from manual processes
    9. 📊 MONITOR expiry — alert early, fix before it's an emergency
    10. 🔐 PROTECT private keys — a compromised key = start over completely

# Common Error Codes

| Error                                           | Meaning                             | Quick Fix                                          |
|-------------------------------------------------|--------------------------------------|----------------------------------------------------|
| `ERR_CERT_DATE_INVALID`                         | Certificate expired                  | Renew certificate                                  |
| `ERR_CERT_AUTHORITY_INVALID`                    | CA not trusted                       | Add CA to trust store                              |
| `ERR_CERT_COMMON_NAME_INVALID`                  | Domain mismatch                      | Reissue with correct SANs                          |
| `ERR_SSL_PROTOCOL_ERROR`                        | TLS version mismatch                  | Update TLS settings                                |
| `SSL_ERROR_RX_RECORD_TOO_LONG`                  | HTTP on HTTPS port                    | Check port configuration                           |
| `PKIX path building failed`                     | Java certificate chain issue          | Add certs to Java truststore                       |
| `certificate has expired`                       | Expired certificate                   | Renew immediately                                  |
| `unable to get local issuer`                    | Missing intermediate certificate      | Fix certificate chain                              |
| `tls: bad certificate`                          | Invalid/untrusted client certificate  | Check mTLS config & CA                             |
| `certificate signed by unknown authority`       | Private CA not trusted                | Distribute CA certificate                          |
