# Scenario 11 - Certificate Works Locally But Fails in Production

## Symptom

Developer: 

    "It works on my machine!"

Production logs:
  
    x509: certificate signed by unknown authority
    SSL handshake failed
    curl: (60) SSL certificate problem

## Diagnostics

### 1) Compare environments

Local machine

    openssl s_client -connect api.company.com:443 -showcerts

Production server 

    kubectl exec -it pod-name -- openssl s_client -connect api.company.com:443 -showcerts
  
### 2) Check trust stores differ

Local machine

    ls /usr/local/share/ca-certificates/  # Ubuntu
    security find-certificate -a           # macOS

Production Container

    kubectl exec -it pod-name -- ls /etc/ssl/certs/

### 3) Compare certificate chains

Are they serving different certs?

    openssl s_client -connect api.company.com:443 2>/dev/null | openssl x509 -noout -fingerprint

## Common causes

    ❌ Internal CA cert installed locally but NOT in container image
    ❌ Different DNS resolution (local hosts file vs production DNS)
    ❌ Load balancer serving different cert than direct server
    ❌ VPN changes certificate path
    ❌ Different CA bundle versions between environments

## Fix

### Add CA to Container Image

Dockerfile

    # Dockerfile
    FROM ubuntu:22.04
    
    # Copy your internal CA certificate
    COPY company-root-ca.crt /usr/local/share/ca-certificates/
    
    # Update trust store
    RUN apt-get update && \
        apt-get install -y ca-certificates && \
        update-ca-certificates
    
    # Verify it's trusted
    RUN openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt \
        /usr/local/share/ca-certificates/company-root-ca.crt

### Kubernetes ConfigMap for CA

Create ConfigMap with CA cert

    kubectl create configmap company-ca --from-file=ca.crt=company-root-ca.crt

Mount CA in pods

    apiVersion: apps/v1
    kind: Deployment
    spec:
      template:
        spec:
          containers:
          - name: my-service
            volumeMounts:
            - name: ca-certs
              mountPath: /usr/local/share/ca-certificates/company-ca.crt
              subPath: ca.crt
          volumes:
          - name: ca-certs
            configMap:
              name: company-ca

