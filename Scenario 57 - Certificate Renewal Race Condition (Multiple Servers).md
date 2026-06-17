# Scenario 57 - Certificate Renewal Race Condition (Multiple Servers).md

## Symptom

Multiple load-balanced servers

Each tries to renew the SAME certificate

Let's Encrypt rate limit hit!

Servers overwrite each other's certs

Inconsistent certs across the fleet

## Diagnostics

### 1) Check renewal logs across all servers

    for server in web1 web2 web3; do
      echo "=== $server ==="
      ssh $server "grep renew /var/log/letsencrypt/letsencrypt.log | tail -5"
    done

### 2) Check if servers have different cert versions

    for server in web1 web2 web3; do
      echo "=== $server ==="
      ssh $server "openssl x509 -in /etc/ssl/cert.crt -noout -dates -serial"
    done

If serials differ → servers have DIFFERENT certs! ❌

### 3) Check renewal cron timing

    for server in web1 web2 web3; do
      ssh $server "crontab -l | grep certbot"
    done

All renewing at the same time = race condition!

## Fix

### 1) Designate ONE renewal server (master)

Only web1 renews, then distributes to others

On master (web1) — renewal hook distributes cert:

    cat > /etc/letsencrypt/renewal-hooks/deploy/distribute.sh << 'EOF'
    #!/bin/bash
    for server in web2 web3; do
      rsync -az /etc/letsencrypt/live/ $server:/etc/letsencrypt/live/
      ssh $server "systemctl reload nginx"
    done
    EOF

Then,

    chmod +x /etc/letsencrypt/renewal-hooks/deploy/distribute.sh

### 2) Use shared storage for certs

Mount certs from shared NFS/EFS

All servers read from the same location

One renewal process updates the shared store

### 3) Use a secret manager (best for scale)

Renew once, store in Vault/AWS Secrets Manager

All servers pull from the central secret store

### 4) Use cert-manager (Kubernetes)

Single source of truth, distributed via secrets

### 5) Distributed lock for renewal

Use a lock (Redis/etcd) so only ONE server renews at a time
