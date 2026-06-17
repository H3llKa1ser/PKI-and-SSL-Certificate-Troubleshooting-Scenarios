# Scenario 56 - Kubernetes Webhook Certificate Mismatch

## Symptom

Admission webhook fails

"x509: certificate signed by unknown authority"

"failed calling webhook: tls: failed to verify certificate"

Deployments hang or get rejected

cert-manager webhook itself failing!

## Diagnostics

### 1) Check webhook configuration

    kubectl get validatingwebhookconfiguration
    kubectl get mutatingwebhookconfiguration

### 2) Examine the caBundle in the webhook

    kubectl get validatingwebhookconfiguration my-webhook -o jsonpath='{.webhooks[0].clientConfig.caBundle}' | base64 -d | openssl x509 -noout -subject -dates

### 3) Check the webhook service's actual cert

    kubectl get secret webhook-tls -n webhook-namespace -o jsonpath='{.data.tls\.crt}' | base64 -d  | openssl x509 -noout -subject -dates

The caBundle must validate the webhook's serving cert!

### 4) Check webhook pod logs

    kubectl logs -n webhook-namespace deploy/webhook-server

## Common causes

    ❌ caBundle not updated when webhook cert rotated
    ❌ Webhook cert expired
    ❌ Self-signed cert but caBundle has different CA
    ❌ Service name doesn't match cert SAN
    ❌ cert-manager CA injection not configured

## Fix

### 1) Use cert-manager's CA injector (automatic!)

    apiVersion: admissionregistration.k8s.io/v1
    kind: ValidatingWebhookConfiguration
    metadata:
      name: my-webhook
      annotations:
        cert-manager.io/inject-ca-from: webhook-namespace/webhook-cert

cert-manager auto-injects the caBundle! ✅

    webhooks:
    - name: validate.example.com
      clientConfig:
        service:
          name: webhook-service
          namespace: webhook-namespace
          path: /validate

caBundle injected automatically by cert-manager

### 2) Manually update caBundle

    CA_BUNDLE=$(kubectl get secret webhook-tls -n webhook-namespace -o jsonpath='{.data.ca\.crt}')

Then

    kubectl patch validatingwebhookconfiguration my-webhook --type='json' -p="[{'op': 'replace', 'path': '/webhooks/0/clientConfig/caBundle', 'value':'${CA_BUNDLE}'}]"

### 3) Ensure cert SAN matches service DNS

Cert SAN must include:

    #   webhook-service.webhook-namespace.svc
    #   webhook-service.webhook-namespace.svc.cluster.local
