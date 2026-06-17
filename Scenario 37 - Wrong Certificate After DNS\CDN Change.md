# Scenario 37 - Wrong Certificate After DNS/CDN Change

## Symptom

Changed DNS / added CDN (CloudFlare, CloudFront)

Now seeing a DIFFERENT certificate than expected!

"This is CloudFlare's cert, not mine!"

Certificate suddenly shows different issuer

## Diagnostics

### 1) Check what cert is being served now

    echo | openssl s_client -connect yoursite.com:443 2>/dev/null | openssl x509 -noout -issuer -subject

If issuer is "CloudFlare Inc" → CDN is terminating SSL!

### 2) Trace the path

    dig yoursite.com

Is it pointing to CDN IPs or your origin?

### 3) Check origin directly (bypass CDN)

    echo | openssl s_client -connect ORIGIN_IP:443 -servername yoursite.com 2>/dev/null | openssl x509 -noout -issuer

### 4) Understand the SSL flow with CDN

## Understanding CDN SSL modes

    CloudFlare/CDN SSL Modes:
    
    1. Flexible:    Client─HTTPS─►CDN─HTTP─►Origin  ⚠️ Insecure to origin!
    2. Full:        Client─HTTPS─►CDN─HTTPS─►Origin (any cert)
    3. Full(Strict):Client─HTTPS─►CDN─HTTPS─►Origin (valid cert) ✅
    4. Origin Pull: CDN serves its cert, validates origin cert
    
    The cert users SEE is the CDN's cert (or your uploaded one)!

## Fix

### 1) Upload your cert to the CDN (if you want your cert shown)

CloudFlare: SSL/TLS → Edge Certificates → Upload Custom Cert (requires Business/Enterprise plan)

### 2) Use CDN's cert (most common, perfectly fine!)

Users see CDN cert — this is normal and secure

### 3) Secure the origin connection (CRITICAL)

Set SSL mode to "Full (Strict)" 

Install an Origin CA certificate on your server:

CloudFlare: SSL/TLS → Origin Server → Create Certificate

### 4) Use authenticated Origin Pulls (mTLS to origin)

CDN presents a client cert your origin verifies

Ensures ONLY the CDN can reach your origin
