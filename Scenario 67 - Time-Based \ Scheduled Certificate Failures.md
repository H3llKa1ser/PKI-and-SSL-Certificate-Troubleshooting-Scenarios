# Scenario 67 - Time-Based / Scheduled Certificate Failures

## Symptom

Certificate works during business hours

Fails at specific times (midnight, weekends)

Intermittent failures with no obvious pattern

"Certificate not yet valid" at certain times only

Daylight saving time transitions cause issues

## Diagnostics

### 1) Check for timezone/DST issues

    date
    timedatectl status | grep -i "time zone\|dst"

### 2) Check cert validity in UTC vs local

    openssl x509 -in cert.crt -noout -dates

Certs use UTC! notBefore/notAfter are GMT

    date -u   # Compare to UTC time

### 3) Check for cron jobs affecting certs

    crontab -l | grep -i cert
    ls /etc/cron.*/  | grep -i cert

### 4) Look for renewal jobs that briefly remove certs

    grep -i "cert\|ssl" /var/log/syslog | grep -i "remove\|delete\|renew"

### 5) Check NTP for periodic time jumps

    journalctl -u chronyd | grep -i "step\|jump"

## Common Time Based Causes

    ❌ DST transition causes 1-hour clock skew
    ❌ NTP correction jumps clock across notBefore
    ❌ Renewal cron briefly removes/replaces cert (race window)
    ❌ Timezone misconfiguration (local vs UTC confusion)
    ❌ Cert valid in one TZ but "not yet valid" in another
    ❌ Scheduled maintenance scripts touching certs

## Fix

### 1) Always use UTC on servers

    timedatectl set-timezone UTC

### 2) Ensure smooth NTP (slew, don't step)

chrony config — slew small offsets gradually

#### /etc/chrony.conf:

    maxslewrate 1000

Avoid large clock jumps during operation

### 3) Make renewal atomic (no removal window)

Write new cert to temp, then atomic move

    mv -f new-cert.crt cert.crt    # Atomic replace

Never: rm cert.crt; cp new-cert.crt cert.crt (race window!)

### 4) Add validity buffer (backdated notBefore)

CAs often backdate notBefore by ~1 hour

This absorbs minor clock skew

### 5) Reload AFTER renewal completes, not during

    certbot renew --deploy-hook "systemctl reload nginx"
