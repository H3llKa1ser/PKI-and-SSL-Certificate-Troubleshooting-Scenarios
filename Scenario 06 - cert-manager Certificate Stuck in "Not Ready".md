# Scenario 6 - cert-manager Certificate Stuck in "Not Ready"

## Symptom

Example

    kubectl get certificate -n payments
    
    NAME                    READY   SECRET                  AGE
    payment-service-cert    False   payment-service-tls     10m
                            ^^^^
                            Stuck! Should be True

## Diagnostics

### 1) Desctibe the certificate

    kubectl describe certificate payment-service-cert -n payments

Look for Events section:

    Events:
      Warning  Issuing  Failed to create CertificateRequest
      Warning  Failed   Error getting keypair for existing CertificateRequest

### 2) Check CertificateRequest

    kubectl get certificaterequest -n payments
    kubectl describe certificaterequest payment-service-cert-xxxxx -n payments

### 3) Check the Issuer/ClusterIssuer

    kubectl describe clusterissuer internal-ca-issuer

### 4) Check cert-manager logs

    kubectl logs -n cert-manager -l app=cert-manager --tail=100

### 5) Check ACME challenges (if using Let's Encrypt)

    kubectl get challenges -A
    kubectl describe challenge <challenge-name> -n payments

## Common Causes and Fixes

### 1) CA Secret not found

Fix: Create the CA Secret

    kubectl create secret tls internal-ca-key-pair --cert=ca.crt --key=ca.key -n cert-manager
     
### 2) ACME HTTP01 challenge failing

Fix: Ensure ingress is reachable from internet

    curl http://yoursite.com/.well-known/acme-challenge/test

### 3) DNS01 challenge failing

Fix: Check DNS provider credentials in secret

### 4) Wrong issuerRef name

Fix: Verify issuer name matches exactly

    kubectl get clusterissuer

### 5) Vault connection failing

Fix: Check vault token/role and connectivity

    kubectl logs -n cert-manager deploy/cert-manager | grep vault
