# Scenario 39 - Multi-SAN Certificate One Domain Validation Fails

## Symptom

Requesting cert for 5 domains

4 validate fine, 1 fails

Entire certificate request fails because of ONE domain!

Let's Encrypt: "Some challenges have failed"

## Diagnostics

### 1) Identify which domain failed

    certbot certonly --nginx -d a.com -d b.com -d c.com -d d.com -d e.com 2>&1 | grep -i "fail\|error"

Output reveals:

Challenge failed for domain c.com

c.com: DNS problem: NXDOMAIN looking up A for c.com

### 2) Test each domain individually

    for domain in a.com b.com c.com d.com e.com; do
      echo "=== $domain ==="
      dig +short $domain                     # DNS resolves?
      curl -sI http://$domain/.well-known/acme-challenge/test
    done

### 3) Check ACME challenge accessibility

For HTTP-01: domain must be reachable on port 80

    curl -v http://c.com/.well-known/acme-challenge/test

## Common Per-Domain Failures

    ❌ DNS not pointing to the right server (NXDOMAIN)
    ❌ One domain behind a firewall/different server
    ❌ CAA record blocking the CA for that domain
    ❌ Port 80 blocked for that specific domain
    ❌ Wildcard domain needs DNS-01, not HTTP-01

## Fix

### 1) Check CAA records (they can block CAs)

    dig CAA c.com

 CAA records specify which CAs can issue for the domain

Example: c.com. CAA 0 issue "letsencrypt.org"

If missing your CA → it can't issue!

#### Add CAA record allowing your CA:

    c.com. IN CAA 0 issue "letsencrypt.org"

### 2) Remove the problematic domain temporarily

Skip c.com

    certbot certonly --nginx -d a.com -d b.com -d d.com -d e.com

### 3) Use DNS-01 challenge (works behind firewalls)

    certbot certonly --dns-cloudflare --dns-cloudflare-credentials ~/.cf.ini -d a.com -d b.com -d c.com -d d.com -d e.com

  ### 4) Fix the DNS for the failing domain first

  Then retry the full request
