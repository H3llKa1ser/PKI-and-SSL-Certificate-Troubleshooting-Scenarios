# Scenario 64 - Certificate Expiry During Long-Lived Connection

## Symptom

Long-running WebSocket/gRPC stream

Connection established fine

But cert expires DURING the connection

New connections fail, existing ones behave oddly

Streaming/persistent connections affected

## Diagnostics

### 1) Check connection duration vs cert validity

Long-lived connections (WebSockets, gRPC streams, DB pools) can outlive certificate validity!

### 2) Check cert remaining validity

    openssl s_client -connect host:443 2>/dev/null | openssl x509 -noout -enddate

### 3) Check active long-lived connections

    ss -tnp | grep ESTABLISHED | grep :443

How long have they been open?

## Understanding the issue

TLS validates the cert at HANDSHAKE time only
Once connected, the session continues even if cert expires!

BUT:

    - New connections during renewal window may fail
    - Some clients re-validate on renegotiation
    - Connection pools may have mixed old/new sessions
    - Reconnection after a blip hits the expired cert

## Fix

### 1) Renew certs well BEFORE expiry (with overlap)

renewBefore should exceed your longest connection lifetime

### 2) Implement connection lifecycle limits

Force reconnection periodically (before cert expiry)

gRPC: set MAX_CONNECTION_AGE

    grpc.max_connection_age_ms = 3600000   # 1 hour max

### 3) Graceful connection draining on renewal

When cert renews, drain old connections gradually

New connections use new cert, old ones finish naturally

### 4) Client-side reconnection with backoff

Clients should handle reconnection gracefully

And pick up the new cert on reconnect
