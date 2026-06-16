# Scenario 18 - Cross-Domain \ Cross-Cluster mTLS Failure

## Symptom

Service in Cluster A cannot connect to Service in Cluster B

Works fine within the same cluster ✅

Fails across clusters ❌

Error: 

    "certificate signed by unknown authority"

Error: 

    "remote error: tls: bad certificate"

## Diagnostics

### 1) Check if different CAs are used per cluster

Cluster A

    kubectl config use-context cluster-a

    kubectl get secret -n istio-system istio-ca-secret -o jsonpath='{.data.ca-cert\.pem}' | base64 -d | openssl x509 -noout -fingerprint

Cluster B

    kubectl config use-context cluster-b

    kubectl get secret -n istio-system istio-ca-secret -o jsonpath='{.data.ca-cert\.pem}' | base64 -d | openssl x509 -noout -fingerprint

### 2) Check SPIFFE trust domain (Secure Production Identity Framework for Everyone)

    kubectl exec -it service-pod -- openssl s_client -connect service-b.cluster-b:8443 -showcerts 2>/dev/null | grep "URI:"
  
#### Look for: URI:spiffe://cluster-b.local/ns/default/sa/service-b

#### Your service needs to trust cluster-b's SPIFFE trust domain

## Fix

### Shared Root CA Approach

Use a common Root CA for all clusters

    🏛️ Enterprise Root CA (shared)
         │
         ├── 🏢 Cluster A Intermediate CA
         │       └── Cluster A workload certs
         │
         └── 🏢 Cluster B Intermediate CA
                 └── Cluster B workload certs

Result: Both clusters trust the same Root CA
        
Cross-cluster mTLS works! ✅

### Istio Multi-Cluster with Shared CA

Create shared root CA

    openssl req -x509 -newkey rsa:4096 -keyout root-key.pem -out root-cert.pem -days 3650 -nodes -subj "/CN=Enterprise Root CA"

Create intermediate CA for each cluster

#### Cluster A

    openssl req -newkey rsa:4096 -keyout cluster-a-key.pem -out cluster-a-csr.pem -nodes -subj "/CN=Cluster A CA"

    openssl x509 -req -in cluster-a-csr.pem -CA root-cert.pem -CAkey root-key.pem -out cluster-a-cert.pem -days 730

Configure Istio to use shared CA

    kubectl create secret generic cacerts -n istio-system --from-file=ca-cert.pem=cluster-a-cert.pem --from-file=ca-key.pem=cluster-a-key.pem --from-file=root-cert.pem=root-cert.pem --from-file=cert-chain.pem=cert-chain.pem

#### Repeat for Cluster B with its own intermediate CA

#### Both clusters share the same root-cert.pem ← Key!

