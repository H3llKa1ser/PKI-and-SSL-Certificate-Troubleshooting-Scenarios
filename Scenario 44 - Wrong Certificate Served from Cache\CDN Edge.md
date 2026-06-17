# Scenario 44 - Wrong Certificate Served from Cache\CDN Edge.md

## Symptom

Updated certificate hours ago

Some users see new cert, others see OLD cert

Geographic inconsistency — works in US, fails in EU

Certificate "flickers" between old and new

## Diagnostics

### 1) Test from multiple geographic locations

Use online tools or different DNS servers

    for dns in 8.8.8.8 1.1.1.1 9.9.9.9; do
      echo "=== via $dns ==="
      dig @$dns yoursite.com +short
    done

### 2) Check cert from different edge locations

CloudFlare example — different colos may have different certs cached

    curl -v --resolve yoursite.com:443:EDGE_IP_1 https://yoursite.com 2>&1 | grep "expire\|subject"

### 3) Check CDN cahce status

    curl -I https://yoursite.com | grep -i "cf-cache\|x-cache\|age"

## Fix

### 1) Purge CDN cache after cert update

CloudFlare:

    curl -X POST "https://api.cloudflare.com/client/v4/zones/ZONE_ID/purge_cache" \
      -H "Authorization: Bearer TOKEN" \
      -H "Content-Type: application/json" \
      --data '{"purge_everything":true}'

CloudFront:

    aws cloudfront create-invalidation \
      --distribution-id DIST_ID \
      --paths "/*"

### 2) Wait for edge propagation

CDN cert deployment can take 5-30 minutes across all edges

### 3) Verify cert is deployed to ALL edge locations

Check CDN dashboard for deployment status
