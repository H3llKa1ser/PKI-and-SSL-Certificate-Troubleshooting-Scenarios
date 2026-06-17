# Scenario 30 - Browser-Specific Certificate Behavior

## Symptom

Works in Firefox ✅ but fails in Chrome ❌

Works in Chrome ✅ but fails in Safari ❌

Mobile Safari behaves differently than desktop

"Your connection is not private" in only ONE browser

## Diagnostics

#### Each browser has DIFFERENT requirements!

### 1) Check what each browser enforces

Chrome:  Requires CT logs, max 398-day validity, strict SAN

Firefox: Uses its OWN trust store (not OS!)

Safari:  Strictest — 398-day max, requires CT, strict on chain

### 2) Validate against each browser's rules

Check certificate validity period

    openssl x509 -in cert.crt -noout -dates

Calculate days — if > 398 days → Chrome/Safari reject!

### 3) Check CT compliance (Chrome/Safari need this)

    openssl x509 -in cert.crt -noout -text | grep SCT

### 4) Check if SAN exists (CN-only fails in Chrome)

    openssl x509 -in cert.crt -noout -text | grep -A1 "Subject Alternative Name"

## Browser-Specific gotchas

    🌐 Chrome:
       ❌ Rejects certs valid > 398 days
       ❌ Requires Certificate Transparency (SCTs)
       ❌ Ignores Common Name — REQUIRES Subject Alternative Name
       ❌ Rejects SHA-1 signatures
    
    🦊 Firefox:
       ⚠️ Uses its OWN trust store (not the OS!)
       → Internal CA must be added to Firefox separately!
       ❌ Strict about mixed content
    
    🧭 Safari:
       ❌ Strictest validity (398 days max)
       ❌ Requires CT
       ❌ Very strict on chain completeness
       ❌ Rejects certs with weak keys

## Fix

### 1) Add internal CA to Firefox specifically

Firefox: Settings → Privacy & Security → Certificates → View Certificates → Authorities → Import

For enterprise — use policies.json:

    cat > /usr/lib/firefox/distribution/policies.json << EOF
    {
      "policies": {
        "Certificates": {
          "ImportEnterpriseRoots": true,
          "Install": ["company-root-ca.crt"]
        }
      }
    }
    EOF

### 2) Keep cert validity ≤ 398 days

When requesting a new cert (Stay under this limit):

    openssl req -new -days 397

### 3) Always include SAN (not just CN)

Chrome ignores CN entirely now!

### 4) Use modern CA that provides SCTs automatically
