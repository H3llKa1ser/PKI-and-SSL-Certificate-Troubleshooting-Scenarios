# Scenario 38 - Certificate Private Key Permissions Issue

## Symptom

Service won't start

"SSL_CTX_use_PrivateKey_file failed"

"Permission denied" loading key

"private key file has group or world access"

nginx: [emerg] cannot load certificate key

## Diagnostics

### 1) Check current permissions

    ls -la /etc/ssl/private/server.key

#### -rw-r--r-- = 644 ← TOO OPEN! ❌

#### -rw------- = 600 ← Correct ✅

### 2) Check ownership

    stat /etc/ssl/private/server.key

#### Owner should match the service user (or root)

### 3) Check SELinux context (RHEL/CentOS)

    ls -Z /etc/ssl/private/server.key
    ausearch -m avc -ts recent | grep ssl

### 4) Verify the service user

    ps aux | grep nginx

Worker runs as: www-data / nginx

## Fix

### 1) Set correct permissions

Owner read/write only

    chmod 600 /etc/ssl/private/server.key

Cert can be world-readable

    chmod 644 /etc/ssl/server.crt

### 2) Set correct ownership

    chown root:root /etc/ssl/private/server.key

OR for service-specific

    chown nginx:nginx /etc/ssl/private/server.key

### 3) Secure the directory too

    chmod 700 /etc/ssl/private/
    chown root:root /etc/ssl/private/

### 4) Fix SELinux context (RHEL/CentOS)

    restorecon -Rv /etc/ssl/private/

OR set the correct context

    semanage fcontext -a -t cert_t "/etc/ssl/private(/.*)?"
    restorecon -Rv /etc/ssl/private/

### 5) For Kubernetes secrets, set defaultMode on the volume:

    volumes:
    - name: tls
      secret:
        secretName: my-tls
        defaultMode: 0600    # ← Restrictive permissions
