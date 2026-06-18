# PKI-and-SSL-Certificate-Troubleshooting-Scenarios

Here you will find playbooks that will assist you with troubleshooting your PKI and SSL certificate infrastructure.

# Troubleshooting Decision Tree

                        ┌─────────────────────────────────┐
                        │   🚨 CERTIFICATE/TLS ERROR        │
                        │   Run: ssl-diagnose.sh first!     │
                        └────────────────┬────────────────┘
                                         │
                                         ▼
                        ┌─────────────────────────────────┐
                        │ Can you even CONNECT? (TCP/DNS)  │
                        └────────┬───────────────┬─────────┘
                              NO │               │ YES
                                 ▼               ▼
                  ┌──────────────────────┐  ┌──────────────────────────┐
                  │ • Check DNS resolves │  │ Did the TLS HANDSHAKE     │
                  │ • Check port open    │  │ complete?                 │
                  │ • Check firewall     │  └──────┬────────────┬───────┘
                  │ • dig / nc / telnet  │      NO │            │ YES
                  └──────────────────────┘         ▼            ▼
                                        ┌──────────────────┐  ┌─────────────────┐
                                        │ HANDSHAKE FAILED │  │ Connected but    │
                                        │ → Go to BRANCH A │  │ cert WARNING?    │
                                        └──────────────────┘  │ → Go to BRANCH B │
                                                              └─────────────────┘
    
    ╔══════════════════════════════════════════════════════════════════════════╗
    ║ BRANCH A: HANDSHAKE FAILURE                                                ║
    ╚══════════════════════════════════════════════════════════════════════════╝
                                         │
                                         ▼
                  ┌──────────────────────────────────────────┐
                  │ "No cipher / protocol" error?             │
                  └──────┬──────────────────────────┬─────────┘
                     YES │                          │ NO
                         ▼                          ▼
            ┌────────────────────────┐  ┌──────────────────────────────┐
            │ CIPHER/VERSION MISMATCH │  │ "Bad certificate" / mTLS?     │
            │ • Check ssl_protocols   │  └──────┬─────────────────┬──────┘
            │ • Check cipher suites   │     YES │                 │ NO
            │ • Test each TLS version │         ▼                 ▼
            │ • Use Mozilla generator │  ┌──────────────┐  ┌──────────────────┐
            └────────────────────────┘  │ mTLS ISSUE    │  │ Connection reset? │
                                         │ • Client cert?│  │ • Firewall/IDS?   │
                                         │ • CA trusted? │  │ • Large ClientHello│
                                         │ • EKU correct?│  │ • MTU/fragmenting │
                                         │ • Key matches?│  │ • Capture w/tcpdump│
                                         └──────────────┘  └──────────────────┘
    
    ╔══════════════════════════════════════════════════════════════════════════╗
    ║ BRANCH B: CERTIFICATE WARNING (connected, but cert rejected)              ║
    ╚══════════════════════════════════════════════════════════════════════════╝
                                         │
                                         ▼
                  ┌──────────────────────────────────────────┐
                  │ 1️⃣ Is the certificate EXPIRED?            │
                  │    openssl x509 -noout -dates             │
                  └──────┬──────────────────────────┬─────────┘
                     YES │                          │ NO
                         ▼                          ▼
            ┌────────────────────────┐  ┌──────────────────────────────────┐
            │ EXPIRED                 │  │ 2️⃣ Does the DOMAIN NAME match?    │
            │ • Renew cert            │  │    Check SAN (not just CN!)       │
            │ • Check WHOLE chain     │  └──────┬─────────────────────┬──────┘
            │   (intermediate too!)   │      NO │                     │ YES
            │ • Check server clock!   │         ▼                     ▼
            │   (clock skew = phantom)│  ┌──────────────┐  ┌──────────────────────┐
            └────────────────────────┘  │ NAME MISMATCH │  │ 3️⃣ Is the CA TRUSTED? │
                                         │ • Reissue w/  │  │   verify -CAfile      │
                                         │   correct SANs│  └──────┬───────────┬────┘
                                         │ • Check IDN/  │      NO │           │ YES
                                         │   punycode    │         ▼           ▼
                                         │ • Wildcard    │  ┌────────────┐  ┌──────────────┐
                                         │   covers it?  │  │ UNTRUSTED  │  │ 4️⃣ CHAIN     │
                                         └──────────────┘  │ CA         │  │   complete & │
                                                           │ • Add CA to│  │   in order?  │
                                                           │   trust    │  └──────┬───┬───┘
                                                           │   store    │      NO │   │ YES
                                                           │ • Self-    │         ▼   ▼
                                                           │   signed?  │  ┌─────────┐ ┌──────────┐
                                                           │ • Proxy/   │  │ CHAIN   │ │ DEEPER    │
                                                           │   TLS      │  │ ISSUE   │ │ ISSUE     │
                                                           │   inspect? │  │ • Add   │ │ → BRANCH C│
                                                           └────────────┘  │   inter-│ └──────────┘
                                                                           │   mediate│
                                                                           │ • Fix    │
                                                                           │   order  │
                                                                           │   (leaf  │
                                                                           │   first!)│
                                                                           └─────────┘
    
    ╔══════════════════════════════════════════════════════════════════════════╗
    ║ BRANCH C: DEEPER / ENVIRONMENTAL ISSUES                                   ║
    ╚══════════════════════════════════════════════════════════════════════════╝
                                         │
                                         ▼
            ┌────────────────────────────────────────────────────────────┐
            │ Works in ONE place but not another? Ask these questions:    │
            ├────────────────────────────────────────────────────────────┤
            │ □ Works in browser, fails in tool/app?                      │
            │     → INCOMPLETE CHAIN (browsers fetch via AIA, tools don't)│
            │                                                             │
            │ □ Works on host, fails in container?                        │
            │     → Missing ca-certificates package in image             │
            │                                                             │
            │ □ Works locally, fails in production?                       │
            │     → Different trust store / internal CA not deployed     │
            │                                                             │
            │ □ Works in browser X, fails in browser Y?                  │
            │     → Validity >398 days / missing SAN / Firefox own store │
            │                                                             │
            │ □ Renewed cert but old one still served?                   │
            │     → Didn't reload/restart! Or LB/CDN caching            │
            │                                                             │
            │ □ Behind corporate network only?                           │
            │     → TLS inspection proxy — add proxy CA                  │
            │                                                             │
            │ □ Java app specifically?                                   │
            │     → Separate truststore (keytool, not OS store)         │
            │                                                             │
            │ □ Intermittent / time-based failures?                      │
            │     → Clock skew / DST / NTP / Year 2038                   │
            │                                                             │
            │ □ First request after idle fails?                          │
            │     → OCSP staple cache expired                           │
            │                                                             │
            │ □ Mass token/login failures after rotation?               │
            │     → JWT signing key rotated without JWKS overlap        │
            └────────────────────────────────────────────────────────────┘
                                         │
                                         ▼
            ┌────────────────────────────────────────────────────────────┐
            │ STILL STUCK? Final checks:                                  │
            │ • openssl x509 -modulus | md5  (cert/key match?)           │
            │ • Check Key Usage / EKU for the purpose                    │
            │ • Check key size & signature algorithm (weak?)            │
            │ • Check Name Constraints on the CA                        │
            │ • Capture full handshake with tcpdump/Wireshark          │
            │ • Test with: testssl.sh / SSL Labs                        │
            └────────────────────────────────────────────────────────────┘

# Golden rules of Certificate Troubleshooting

## How to investigate

    1. 🔍 GATHER FACTS FIRST
       Run diagnostics before touching anything. Read the EXACT
       error message — it almost always names the precise problem.
    
    2. 📅 CHECK EXPIRY FIRST, ALWAYS
       It's the #1 cause of certificate issues. Check it before
       anything else. Then check the ENTIRE chain, not just the leaf.
    
    3. 🔗 THE CHAIN MATTERS MORE THAN THE LEAF
       An incomplete or wrongly-ordered chain breaks everything.
       Order: leaf → intermediate → root. Each cert's issuer must
       be the next cert's subject.
    
    4. 🏷️ SANs ARE KING — CN IS DEAD
       Modern browsers IGNORE Common Name entirely. The Subject
       Alternative Name (SAN) is what matters. Always check it.
    
    5. 🌐 "WHERE" IS AS IMPORTANT AS "WHAT"
       Works in browser but not curl? Host but not container?
       Locally but not prod? The DIFFERENCE points to the cause
       (usually trust store or chain completeness).
    
    6. 🔑 VERIFY THE CERT/KEY MATCH
       A mismatched cert and private key cause cryptic errors.
       Compare moduli: they MUST produce the same hash.
    
    7. ⏰ WHEN IN DOUBT, CHECK THE CLOCK
       Clock skew, wrong timezone, DST, and NTP jumps cause
       phantom "not yet valid" / "expired" errors. Use UTC.
    
    8. 📝 READ LOGS RELIGIOUSLY
       Web server logs, app logs, cert-manager logs — the exact
       error code tells you exactly which layer failed.

## How to fix and prevent

    9. 🔄 RENEWED ≠ DEPLOYED
       Updating the file on disk does NOTHING until you reload or
       restart the service. Apps cache certs in memory at startup.
       Don't forget LBs and CDNs cache too!
    
    10. 🧪 TEST IN STAGING FIRST
        Especially for Let's Encrypt (rate limits!), CA migrations,
        and anything involving pinning. Use --staging.
    
    11. 🔐 PROTECT PRIVATE KEYS ABSOLUTELY
        chmod 600, store in HSM/Vault, never commit to Git, never
        log them. A compromised key = start completely over.
    
    12. 🤖 AUTOMATE OR DIE
        90% of all certificate incidents come from manual processes.
        If a human must remember to renew it, it WILL eventually fail.
    
    13. 📊 MONITOR EVERYTHING, ALERT EARLY
        You can't fix what you can't see. Monitor the FULL chain.
        Alert at 30, 14, and 7 days before expiry.
    
    14. 🔁 PLAN FOR ROTATION FROM DAY ONE
        Every cert, key, CA, and pin WILL change someday. Build in
        OVERLAP (trust both old + new during transition) for zero
        downtime. Reuse keys when pinning is involved.
    
    15. 🌍 SERVE THE FULL CHAIN — DON'T RELY ON AIA
        Browsers fetch missing intermediates automatically; tools,
        apps, and APIs often don't. Always serve the complete chain.
    
    16. 📦 KNOW YOUR FORMATS
        PEM vs DER vs PKCS#12 vs JKS confusion is common. Identify
        the format (file cert.crt) before converting.

## 5 standard questions to ask

    ┌──────────────────────────────────────────────────┐
    │  When ANY cert issue appears, ask in this order:  │
    │                                                    │
    │  1. Is it EXPIRED?      (whole chain, not leaf)    │
    │  2. Does the NAME match? (SAN, and punycode for IDN)│
    │  3. Is the CHAIN complete & in order?              │
    │  4. Is the CA TRUSTED by THIS client/environment?  │
    │  5. Did you RELOAD/RESTART after the change?        │
    └──────────────────────────────────────────────────┘

# Common Error Codes

## Browser Error Codes

| Error Code                                        | Meaning                               | Most Likely Cause                                | Quick Fix                                           |
|---------------------------------------------------|---------------------------------------|--------------------------------------------------|-----------------------------------------------------|
| `NET::ERR_CERT_DATE_INVALID`                      | Cert expired or not yet valid         | Expired certificate OR clock skew                | Renew certificate / fix server clock               |
| `NET::ERR_CERT_AUTHORITY_INVALID`                 | CA not trusted                        | Self‑signed, internal CA, or incomplete chain    | Add CA to trust store / fix certificate chain       |
| `NET::ERR_CERT_COMMON_NAME_INVALID`               | Domain mismatch                       | SAN doesn’t match URL                            | Reissue with correct Subject Alternative Names      |
| `NET::ERR_CERT_REVOKED`                           | Certificate was revoked                | Key compromise / certificate cancelled           | Get a new certificate                               |
| `NET::ERR_CERT_WEAK_SIGNATURE_ALGORITHM`          | Weak crypto (e.g., SHA‑1)              | Outdated signature algorithm                     | Reissue with SHA‑256 or stronger                    |
| `NET::ERR_CERTIFICATE_TRANSPARENCY_REQUIRED`      | Missing Certificate Transparency logs  | Old cert without SCTs                            | Reissue from a modern CA                            |
| `NET::ERR_SSL_PROTOCOL_ERROR`                     | Protocol negotiation failed            | TLS version mismatch                             | Update TLS configuration                            |
| `NET::ERR_SSL_VERSION_OR_CIPHER_MISMATCH`         | No common cipher/version               | Disabled protocols or ciphers                    | Align client & server protocol/cipher settings      |
| `SSL_ERROR_BAD_CERT_DOMAIN` (Firefox)             | Domain mismatch                        | SAN doesn’t match                                | Reissue with correct SANs                           |
| `SEC_ERROR_UNKNOWN_ISSUER` (Firefox)              | Unknown Certificate Authority          | Firefox has its own trust store                  | Add CA to Firefox trust store                       |
| `SSL_ERROR_NO_CYPHER_OVERLAP` (Firefox)           | No shared cipher                       | Cipher mismatch                                  | Enable compatible ciphers                           |
| `ERR_SSL_OBSOLETE_VERSION`                        | Old TLS version                        | TLS 1.0/1.1 still in use                         | Upgrade to TLS 1.2 or TLS 1.3                        |
| `Mixed Content` warning                           | HTTP resource on HTTPS page            | `http://` links embedded in HTTPS page           | Change all resources to load over `https://`        |

## OpenSSL Error Codes (Verify return code)

| Code | Error                              | Meaning                                    | Quick Fix                                         |
|------|------------------------------------|--------------------------------------------|---------------------------------------------------|
| `0`  | ok                                 | ✅ Verification succeeded                   | No action needed                                  |
| `2`  | unable to get issuer certificate   | Missing CA in chain                        | Provide the CA certificate                        |
| `7`  | certificate signature failure      | Tampered or wrong issuer                   | Verify correct intermediate certificate           |
| `9`  | certificate is not yet valid       | `notBefore` date is in the future           | Check clock / wait until valid                    |
| `10` | certificate has expired            | Past the `notAfter` date                    | Renew certificate                                 |
| `18` | self-signed certificate            | Self-signed cert                            | Use CA‑signed certificate or add to trust store   |
| `19` | self-signed cert in chain          | Root not trusted                            | Add root certificate to trust store               |
| `20` | unable to get local issuer cert    | **Incomplete chain (very common!)**         | Add intermediate certificate                      |
| `21` | unable to verify the first cert    | Missing intermediate                        | Serve full chain                                  |
| `24` | invalid CA certificate             | CA constraints issue                        | Check `basicConstraints` extension                |
| `26` | unsupported certificate purpose    | Wrong Extended Key Usage (EKU)              | Reissue with correct EKU                          |
| `27` | certificate not trusted            | Root not in trust store                      | Add CA to trust store                             |

## Java / Application Error Codes

| Error                                            | Meaning                              | Quick Fix                                         |
|--------------------------------------------------|--------------------------------------|---------------------------------------------------|
| `PKIX path building failed`                      | Can't build trust chain              | Import CA into Java truststore using `keytool`    |
| `unable to find valid certification path`        | Missing CA/intermediate               | Add CA/intermediate to `cacerts` truststore       |
| `SunCertPathBuilderException`                    | Java certificate chain validation failed | Import full certificate chain into truststore  |
| `CertificateExpiredException`                    | Certificate expired                   | Renew certificate                                 |
| `CertificateNotYetValidException`                | Certificate `notBefore` date in future| Fix system clock or wait until valid              |
| `No subject alternative names matching`          | SAN (Subject Alternative Name) mismatch | Reissue with correct SANs                       |
| `bad_certificate`                                | Client certificate rejected (mTLS)   | Check client cert validity & ensure CA is trusted |
| `received fatal alert: handshake_failure`        | Handshake negotiation failed         | Align protocols, ciphers, and certificate config  |

## Go / Modern App Error Codes

| Error                                                      | Meaning                                | Quick Fix                                         |
|------------------------------------------------------------|----------------------------------------|---------------------------------------------------|
| `x509: certificate signed by unknown authority`            | Untrusted Certificate Authority (CA)   | Add CA to system or application trust store       |
| `x509: certificate has expired or is not yet valid`        | Certificate expired OR clock issue     | Renew certificate / fix system clock              |
| `x509: certificate is valid for X, not Y`                  | SAN (Subject Alternative Name) mismatch| Reissue certificate with correct SANs             |
| `tls: bad certificate`                                     | Certificate rejected (often in mTLS)   | Check client certificate validity and CA trust    |
| `tls: failed to verify certificate`                        | Certificate verification failed        | Check certificate chain and trust anchor          |
| `remote error: tls: unknown certificate authority`         | Server doesn't trust the client CA     | Add client CA to the server's trust configuration |

## Kubernetes / cert-manager Error Codes

| Error / Status                                      | Meaning                                         | Quick Fix                                              |
|-----------------------------------------------------|-------------------------------------------------|--------------------------------------------------------|
| `Certificate READY: False`                          | cert-manager couldn't issue the certificate    | Run `kubectl describe certificate` and review events   |
| `Fake Kubernetes Ingress Certificate`               | TLS secret missing or not found                 | Create TLS secret in the correct namespace             |
| `failed calling webhook: x509...`                   | Webhook `caBundle` mismatch                     | Use cert-manager CA Injector to update CA bundle       |
| `x509: certificate has expired` (API)               | Control plane certificate expired               | Run `kubeadm certs renew all`                          |
| `secret not found`                                  | Ingress references missing TLS secret           | Verify `secretName` and namespace                      |
| `Order/Challenge pending`                           | ACME validation is failing                      | Check DNS or HTTP-01 challenge accessibility           |
| `node NotReady` (TLS-related)                       | kubelet certificate expired                     | Enable `rotateCertificates: true` in kubelet config    |

## Web Server Error Codes (Logs)

| Error                                   | Server        | Meaning                             | Quick Fix                                    |
|-----------------------------------------|---------------|--------------------------------------|----------------------------------------------|
| `SSL_CTX_use_PrivateKey_file failed`    | Nginx         | Key load failed                      | Check key path/permissions/match             |
| `key values mismatch`                   | Nginx/Apache  | Certificate & key don't match         | Use matching cert/key pair                   |
| `PEM_read_bio:bad decrypt`               | OpenSSL       | Encrypted key / wrong passphrase      | Decrypt key or provide passphrase            |
| `no start line`                          | OpenSSL       | Wrong format (DER interpreted as PEM) | Convert DER → PEM                            |
| `cannot load certificate`               | Nginx         | Bad path or format                    | Verify file path & format                    |
| `SSL handshake failed`                   | Nginx         | Various (see logs/context)            | Check logs for specific cause                 |
| `unable to get local issuer certificate` | curl/Nginx    | Incomplete certificate chain          | Serve `fullchain.crt`                         |

# Resource to train/test

### 1) badssl.com

    https://badssl.com/
