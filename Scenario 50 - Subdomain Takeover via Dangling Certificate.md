# Scenario 51 - Subdomain Takeover via Dangling Certificate

## Symptom

Security team alert: "Subdomain takeover possible!"

Old subdomain points to deleted cloud resource

Attacker could claim the subdomain + get a valid cert!

crt.sh shows certs for subdomains you forgot about

## Diagnostics

### 1) Find ALL certificates ever issued for your domain

    curl -s "https://crt.sh/?q=%.yourcompany.com&output=json" | jq -r '.[].name_value' | sort -u

#### This reveals subdomains you may have forgotten!

    old-app.yourcompany.com
    test-staging.yourcompany.com
    legacy-api.yourcompany.com   ← Still has certs but resource gone?

### 2) Check for dangling DNS records

    for sub in $(curl -s "https://crt.sh/?q=%.yourcompany.com&output=json" \
      | jq -r '.[].name_value' | sort -u); do
      CNAME=$(dig +short CNAME $sub)
      if [ -n "$CNAME" ]; then
        # Check if the target still exists
        dig +short $CNAME | grep -q . || echo "⚠️ DANGLING: $sub → $CNAME"
      fi
    done

### 3) Check for common takeover targets

CNAME pointing to:

    #   - Deleted S3 buckets
    #   - Removed Heroku apps
    #   - Deprovisioned Azure/GitHub Pages

## Why is this dangerous

1. You created app.company.com → CNAME to my-app.herokuapp.com

2. You deleted the Heroku app (forgot the DNS record!)

3. Attacker registers my-app.herokuapp.com

4. Attacker now controls app.company.com content

5. Attacker gets a VALID Let's Encrypt cert for app.company.com!

6. Attacker can phish your users with a "legitimate" HTTPS site! 💀


## Fix

### 1) Remove dangling DNS records immediately

Delete the CNAME/A record for abandoned subdomains

### 2) Set up CAA records to limit cert issuance

    yourcompany.com. CAA 0 issue "digicert.com"

This restricts WHO can issue certs for your domain

### 3) Monitor CT logs continuously

Set up alerts for ANY new cert issued for your domains

Tools: Cert Spotter, Facebook CT Monitor, crt.sh alerts

### 4) Implement a subdomain inventory process

Track every subdomain and its backing resource

Decommission cleanly: remove resource AND DNS together
