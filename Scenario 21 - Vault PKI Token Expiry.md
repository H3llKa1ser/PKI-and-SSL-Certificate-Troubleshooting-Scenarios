# Scenario 21 - Vault PKI Token Expiry

## Symptom

cert-manager cannot issue new certificates

Logs show: 

    "403 Forbidden — permission denied"

Error: 

    "vault: error renewing token: Error making API request"

Existing certs fine, but new ones fail to issue

## Diagnostics

### 1) Check vault token status

    vault token lookup -address https://vault.company.com -token <your-token>

Output shows

    Key                  Value
    expire_time          2024-01-01T00:00:00Z  ← EXPIRED! ❌
    ttl                  0s                    ← No time left!

### 2) Check cert-manager Vault seccret

    kubectl get secret vault-token -n cert-manager -o jsonpath='{.data.token}' | base64 -d

### 3) Check vault audit logs

    vault audit list

Look for 403 errors in audit log

### 4) Verify Vault PKI mount is healthy

    vault secrets list

    vault pki health-check pki/

## Fix

### 1) Renew the Vault token

    vault token renew -address https://vault.company.com <token>

### 2) Create a long-lived token (better: use Kubernetes auth!)

    vault token create \
      -policy=cert-manager-policy \
      -ttl=8760h \                    # 1 year
      -renewable=true \
      -display-name=cert-manager

Update cert-manager secret with new token

    kubectl create secret generic vault-token -n cert-manager --from-literal=token=<new-token> --dry-run=client -o yaml | kubectl apply -f -

### 3) Best Practice - Use Kubernetes Auth (No token needed)

cert-manager authenticates to Vault using its Kubernetes SA token

No manually managed token = no token expiry problems!

    vault auth enable kubernetes

    vault write auth/kubernetes/config kubernetes_host="https://kubernetes.default.svc"

    vault write auth/kubernetes/role/cert-manager bound_service_account_names=cert-manager bound_service_account_namespaces=cert-manager policies=cert-manager-policy ttl=1h

