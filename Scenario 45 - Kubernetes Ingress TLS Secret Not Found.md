# Scenario 45 - Kubernetes Ingress TLS Secret Not Found.md

## Symptom

Ingress shows no certificate / fake Kubernetes cert

kubectl describe ingress shows:

    "Error getting SSL certificate: secret not found"

Browser shows: 

    "Kubernetes Ingress Controller Fake Certificate"

HTTPS works but with WRONG cert

## Diagnostics

### 1) Check the ingress TLS config

    kubectl get ingress my-ingress -o yaml | grep -A5 "tls:"

Output shows expected secret:

    # tls:
    # - hosts:
    #   - example.com
    #   secretName: example-tls    ← This secret must exist!

### 2) Check if the secret exists in the same namespace

    kubectl get secret example-tls -n my-namespace

Error "not found" → secret missing or wrong namespace!

### 3) Verify secret type and contents

    kubectl get secret example-tls -o yaml

#### type: kubernetes.io/tls  ← Must be this type!

#### data must have: tls.crt AND tls.key

### 4) Check ingress controller logs

    kubectl logs -n ingress-nginx deploy/ingress-nginx-controller | grep -i "ssl\|cert\|secret"

## Causes and fixes

### 1) Secret in wrong namespace

Ingress and secret MUST be in the same namespace!

    kubectl get secret example-tls -n my-namespace   # Check!

### 2) Wrong secret type

Fix: Recreate as TLS type

    kubectl create secret tls example-tls --cert=cert.crt --key=private.key -n my-namespace

### 3) cert-manager did not finish issuing

    kubectl get certificate -n my-namespace
    kubectl describe certificate example-tls -n my-namespace

### 4) Secret name typo in ingress

    kubectl edit ingress my-ingress

Verify secretName matches actual secret name exactly

### 5) Certificate/key data corrupted

Verify the secret data is valid:

    kubectl get secret example-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -subject
  
