# Scenario 50 - mTLS Certificate Rotation Causing Downtime

## Symptom

During cert rotation, services lose connection

"Brief" outage becomes a cascading failure

Service A updated but Service B still has old CA

Microservices can't authenticate during rotation window

## Diagnostics

### 1) Identify the rotation strategy in use

Are you rotating the CA or just leaf certs?

### 2) Check if services trust BOTH old and new CA

    kubectl get secret -n service-a ca-bundle -o jsonpath='{.data.ca\.crt}' | base64 -d | openssl x509 -noout -subject -dates

### 3) Check timing of rotation across services

Did all services update simultaneously? (They shouldn't have to!)

## Rotation problem

    ❌ BAD: Hard cutover
       T0: Everyone trusts CA-old
       T1: Switch everyone to CA-new (SIMULTANEOUSLY)
       → Any service not updated EXACTLY at T1 fails!
    
    ✅ GOOD: Overlapping trust (bundle approach)
       T0: Everyone trusts [CA-old]
       T1: Everyone trusts [CA-old, CA-new]  ← Both!
       T2: Issue new certs from CA-new
       T3: Everyone trusts [CA-new] only
       → Zero downtime!

## Fix (Zero downtime CA rotation)

Manually

### 1) Create a CA bundle with BOTH old and new CA

    kubectl create secret generic ca-bundle --from-file=ca.crt=combined-ca.crt   # old-ca.crt + new-ca.crt

combined-ca.crt contains:

    # -----BEGIN CERTIFICATE-----  (old CA)
    # -----END CERTIFICATE-----
    # -----BEGIN CERTIFICATE-----  (new CA)
    # -----END CERTIFICATE-----

### 2) Roll out bundle to all services (they now trust both)

    kubectl rollout restart deployment --all -n production

### 3) Issue new leaf certs from new CA (services still trust old too)

### 4) Once all services use new certs, remove old CA from bundle

Cert-manager (Automatic)

cert-manager handles overlap automatically

    apiVersion: cert-manager.io/v1
    kind: Certificate
    spec:
      duration: 24h
      renewBefore: 8h      # Renew with overlap window
      secretName: service-tls

cert-manager keeps the secret updated seamlessly

Use trust-manager to distribute CA bundles!

Use trust-manager (companion to cert-manager) to distribute CA bundles across namespaces during rotation! 
