# Scenario 47 - TLS Inspection/Proxy Breaking Certificates

## Symptom

App works at home, fails on corporate network

Certificate issued by "Corporate Proxy CA" not real CA

"certificate signed by unknown authority" on corporate WiFi

API calls fail behind corporate firewall

Python/Node apps reject the proxy's cert

## Diagnostics

### 1) Check who actually issued the cert you receive

    echo | openssl s_client -connect api.external.com:443 2>/dev/null | openssl x509 -noout -issuer

On corporate network you might see:

    # issuer=CN=Corporate Proxy CA, O=YourCompany  ← Proxy intercepting!
    # Instead of:
    # issuer=CN=DigiCert  ← The real CA

### 2) Confirm TLS inspection is happening

The proxy decrypts and re-encrypts with ITS cert

This is "SSL/TLS Inspection" or "Deep Packet Inspection"

### 3) Check if proxy CA is in your trust store

    ls /etc/ssl/certs/ | grep -i corporate

## TLS Inspection Explanation

    Normal:
      You ──TLS──► api.external.com (real cert)
    
    With TLS Inspection (corporate proxy):
      You ──TLS──► Proxy ──TLS──► api.external.com
           (proxy cert)    (real cert)

The proxy decrypts your traffic to inspect it,
then re-encrypts with ITS OWN certificate!

## Fix

### 1) Add corporate CA to trust stores

System:

    cp corporate-proxy-ca.crt /usr/local/share/ca-certificates/
    update-ca-certificates

### 2) Configure language specific trust

Python (requests)

    export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

Or in code:

    requests.get(url, verify='/path/to/corporate-ca.crt')

Node.js

    export NODE_EXTRA_CA_CERTS=/path/to/corporate-ca.crt

Java

    keytool -import -alias corp-proxy -file corporate-proxy-ca.crt -keystore $JAVA_HOME/lib/security/cacerts

Git

    git config --global http.sslCAInfo /path/to/corporate-ca.crt

pip

    pip config set global.cert /path/to/corporate-ca.

npm

    npm config set cafile /path/to/corporate-ca.crt

curl

    curl --cacert /path/to/corporate-ca.crt https://api.external.com

Or set globally:

    export CURL_CA_BUNDLE=/path/to/corporate-ca.crt

AWS CLI

    export AWS_CA_BUNDLE=/path/to/corporate-ca.crt

Docker (add to image)

    COPY corporate-ca.crt /usr/local/share/ca-certificates/
    RUN update-ca-certificates

## Prevention and Best Practice

□ Corporate IT should distribute proxy CA via group policy/MDM

□ Document the proxy CA location for developers

□ Add proxy CA to base container images

□ Some APIs use certificate pinning — these will STILL fail! (Pinned apps can't be intercepted — by design)

□ Consider proxy bypass lists for pinned/sensitive services
