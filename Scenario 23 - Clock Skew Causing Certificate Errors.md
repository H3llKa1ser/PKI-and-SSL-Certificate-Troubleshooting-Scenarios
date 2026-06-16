# Scenario 23 - Clock Skew Causing Certificate Errors

## Symptom

"Certificate not yet valid" — but it's clearly valid!

Intermittent SSL failures on some servers only

Error: 

    x509: certificate has expired or is not yet valid:
           current time 2026-06-16 is before 2026-06-15 (notBefore)

## Diagnostics

### 1) Check the server's current time

    date
    timedatectl status

### 2) Compare with actual time

    curl -s --head http://google.com | grep -i "^date:"

OR

    https://time.is

### 3) Compare cert validity with system time

    openssl x509 -in cert.crt -noout -dates

Compare in UTC

    date -u

#### If notBefore is in the FUTURE relative to system clock → clock skew!

### 4) Check NTP sync status

systemd-timesyncd

    timedatectl show-timesync status

chrony

    chronyc tracking

ntpd

    ntpq -p

#### Look for: "System clock synchronized: yes" ✅

## Fix

### 1) Sync the clock immediately

chrony (recommended)

    chronyc makestep
    systemctl restart chronyd

systemd-timesyncd

    timedatectl set-ntp true
    systemctl restart systemd-timesyncd

Manual Sync

    sudo ntpupdate -u pool.nto.org

### 2) Set correct timezone

    timedatectl set-timezone UTC

### 3) Ensure NTP is always running

    systemctl enable chronyd
    systemctl enable systemd-timesyncd

## Prevention

□ Always run NTP on ALL servers

□ Monitor clock drift with alerts

□ In Kubernetes — ensure nodes sync time

□ In containers — they inherit host clock (fix the host!)

□ Cloud VMs — enable cloud provider's time sync service

