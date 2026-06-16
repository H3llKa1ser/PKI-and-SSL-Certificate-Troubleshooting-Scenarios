# Scenario 20 - Let's Encrypt Rate Limiting

## Symptom

certbot renew → Error!

Error: 

    too many certificates already issued for
       "yourdomain.com": see https://letsencrypt.org/docs/rate-limits/

HTTP 429: Too Many Requests

## Let's Encrypt Rate Limits

    📊 Current Limits:
       ├── 50 certificates per registered domain per week
       ├── 5 duplicate certificates per week
       ├── 5 failed validation attempts per account per hour
       ├── 300 new orders per account per 3 hours
       └── 100 names per certificate (SAN limit)

## Diagnostics

### 1) Check your current certificate usage

    https://crt.sh/?q=yourdomain.com

Count certs issued this week

### 2) Check renewal frequency

    grep "renew" /var/log/letsencrypt/letsencrypt.log | tail -50

### 3) Check for duplicate renewal attempts

Multiple servers renewing the same cert?

    grep "certificate not yet due for renewal" /var/log/letsencrypt/letsencrypt.log

### 4) Test without hitting rate limits

Use staging environment!

    certbot certonly --staging --nginx -d yourdomain.com

Staging = fake certs but NO rate limits ✅

## Fix

### 1) Use staging to test, production to deploy (Always test with --staging first!)

Staging

    certbot certonly --staging -d yourdomain.com

Production

    certbot certonly -d yourdomain.com

### 2) Consolidate multiple domains into one cert

Instead of separate certs for each subdomain:

    certbot certonly -d yourdomain.com -d www.yourdomain.com -d api.yourdomain.com -d mail.yourdomain.com

Counts as 1 certificate, not 4! ✅

### 3) Share cert across multiple servers (do not renew separately)

Use a central renewal server and distribute cert via:

    # - Shared storage
    # - S3 bucket
    # - Secret manager

### 4) If rate limited - wait!

Rate limits reset weekly (every 7 days from first cert issued)

Check exact reset time at: https://crt.sh

### 5) Request rate limit increase

For large organizations:

https://isrg.formstack.com/forms/lets_encrypt_rate_limit_adjustment_request
