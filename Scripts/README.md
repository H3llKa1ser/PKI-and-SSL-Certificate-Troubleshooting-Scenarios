# Certdoctor - Comprehensive PKI/SSL Diagnostics Script

## Usage

### 1) Make it executable

    chmod +x certdoctor.sh

### 2) Check a single live host

    ./certdoctor.sh example.com

### 3) Custom port + multiple hosts at once

    ./certdoctor.sh example.com:8443 api.example.com mail.example.com:465

### 4) Check local certificate files (expiry, SAN, key match, format, permissions)

    ./certdoctor.sh --file server.crt --key server.key --ca ca-bundle.crt

### 5) Batch-check a whole fleet from a file

    echo "example.com" > hosts.txt
    echo "api.example.com:8443" >> hosts.txt
    ./certdoctor.sh --list hosts.txt

### 6) Only show problems (great for cron/CI)

    ./certdoctor.sh --quiet example.com

### 7) Tune thresholds

    WARN_DAYS=60 CRIT_DAYS=14 ./certdoctor.sh example.com
