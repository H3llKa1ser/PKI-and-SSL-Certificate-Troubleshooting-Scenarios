# Scenario 55 - ACME DNS-01 Challenge Propagation Delays

## Symptom

Wildcard cert request fails

"DNS problem: NXDOMAIN looking up TXT for _acme-challenge"

"Incorrect TXT record found"

Works sometimes, fails other times (flaky!)

Let's Encrypt validates before DNS propagates

## Diagnostics

### 1) Check if the TXT record exists

    dig TXT _acme-challenge.yourdomain.com +short

### 2) Check from multiple DNS servers (propagation check)

    for dns in 8.8.8.8 1.1.1.1 9.9.9.9 208.67.222.222; do
      echo "=== via $dns ==="
      dig @$dns TXT _acme-challenge.yourdomain.com +short
    done

#### If they DIFFER → DNS not fully propagated yet!

### 3) Check the authoritative nameserver directly

    NS=$(dig +short NS yourdomain.com | head -1)
    dig @$NS TXT _acme-challenge.yourdomain.com +short

### 4) Check DNS TTL (high TTL = slow propagation)

    dig _acme-challenge.yourdomain.com TXT

## Fix

### 1) Add propagation wait time

    certbot certonly \
      --dns-cloudflare \
      --dns-cloudflare-credentials ~/.cf.ini \
      --dns-cloudflare-propagation-seconds 60 \   # Wait 60s for propagation
      -d "*.yourdomain.com"

### 2) Lower DNS TTL before requesting cert

Set TTL to 60 seconds on the zone (do this in advance)

### 3) Use a dedicated ACME DNS service

    # acme-dns: a purpose-built DNS server for ACME challenges
    # CNAME _acme-challenge.yourdomain.com to acme-dns
    # Solves propagation issues permanently

### 4) Verify DNS provider API credentials work

Test the API can actually create/delete TXT records

### 5) For manual mode, verify BEFORE continuing

    certbot certonly --manual --preferred-challenges dns -d "*.yourdomain.com"

Wait, verify with dig, THEN press Enter
