# Scenario 5 - Kubernetes Control Plane Certificate Expired

## Symptom

kubectl get nodes → Error: 

    Unable to connect to the server

API server logs: 

    "tls: failed to verify client's certificate"

Error: 

    "x509: certificate has expired or is not yet valid"

In short, your entire cluster is down!

## Diagnostics

### 1) Check all control plane cert expiry

    kubeadm certs check-expiration

### 2) Direct check on cert file

    openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates

## Fix

### 1) Renew ALL certificate at once

    kubeadm certs renew all

### 2) Restart control plane components

They run as static pods — move manifests to trigger restart

    cd /etc/kubernetes/manifests/
    mv kube-apiserver.yaml /tmp/
    mv kube-controller-manager.yaml /tmp/
    mv kube-scheduler.yaml /tmp/

Wait for containers to stop, then move back

    sleep 10
    mv /tmp/kube-apiserver.yaml .
    mv /tmp/kube-controller-manager.yaml .
    mv /tmp/kube-scheduler.yaml .

### 3) Update kubeconfig

    cp /etc/kubernetes/admin.conf ~/.kube/config

### 4) Verify cluster is back

    kubectl get nodes
    kubectl get pods -A

## Prevention

Set up a cron job to auto-renew certs

Add to crontab (runs monthly):

    0 0 1 * * kubeadm certs renew all && \
      systemctl restart kubelet

Monitor cert expiry with Prometheus

Alert when cert expires in < 30 days
