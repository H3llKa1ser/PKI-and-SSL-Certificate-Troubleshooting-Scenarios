# Scenario 60 - Certificate Caching in Application Runtime

## Symptom

Renewed cert on disk, reloaded web server

But the APPLICATION still uses old cert!

Java/Node/.NET app cached cert at startup

Connection pool holds old TLS sessions

Long-running processes never pick up new cert

## Diagnostics

### 1) Confirm disk has new cert

    openssl x509 -in /app/certs/cert.pem -noout -dates

### 2) Check what the running app actually uses

Connect to the app and check

    echo | openssl s_client -connect app-host:8443 2>/dev/null | openssl x509 -noout -dates

#### If app shows OLD cert but disk has NEW → runtime caching!

### 3) Check process start time vs cert update time

    ps -o lstart= -p $(pgrep -f myapp)
    stat /app/certs/cert.pem

App started BEFORE cert update = cached old cert

## Common runtime caching issues

    ☕ Java:    SSLContext loaded once at startup
    🟢 Node.js: https.createServer holds cert in memory
    🔷 .NET:    X509Certificate cached in connection handlers
    🐍 Python:  ssl.SSLContext loaded once
    🔌 Conn pools: Existing connections keep old session

## Fix

### 1) Java

    // Java — Implement SSLContext reloading
    // Use a custom KeyManager that re-reads the cert
    public class ReloadableKeyManager extends X509ExtendedKeyManager {
        private volatile X509KeyManager delegate;
    
        public void reload() throws Exception {
            KeyStore ks = KeyStore.getInstance("PKCS12");
            ks.load(new FileInputStream("cert.p12"), password);
            KeyManagerFactory kmf = KeyManagerFactory.getInstance("SunX509");
            kmf.init(ks, password);
            this.delegate = (X509KeyManager) kmf.getKeyManagers()[0];
        }
        // Delegate methods to this.delegate...
    }

### 2) JavaScript

    // Node.js — Use SNICallback for dynamic cert loading
    const https = require('https');
    const fs = require('fs');
    const tls = require('tls');
    
    const server = https.createServer({
        SNICallback: (servername, cb) => {
            // Re-read cert on each connection (or cache with TTL)
            const ctx = tls.createSecureContext({
                cert: fs.readFileSync('/app/certs/cert.pem'),
                key: fs.readFileSync('/app/certs/key.pem')
            });
            cb(null, ctx);
        }
    });

### 3) Restart on renewal (universal solution)

certbot deploy hook

    certbot renew --deploy-hook "systemctl restart myapp"

Or graceful reload signal if app supports it

    kill -HUP $(pgrep -f myapp)

For Kubernetes — rollout restart

    kubectl rollout restart deployment/myapp
