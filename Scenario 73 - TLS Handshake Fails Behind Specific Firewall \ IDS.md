# Scenario 73 - TLS Handshake Fails Behind Specific Firewall \ IDS.md

## Symptom

TLS works everywhere except behind specific firewall

"connection reset" mid-handshake

Large ClientHello dropped

TLS 1.3 fails but 1.2 works (or vice versa)

Deep packet inspection breaking handshakes

## Diagnostics

### 1) Capture the handshake

    sudo tcpdump -i any -w handshake.pcap host TARGET and port 443

### 2) Test different TLS versions

    for v in 1_2 1_3; do
      echo "=== TLS $v ==="
      echo | openssl s_client -connect host:443 -tls$v 2>&1 \
        | grep -i "connected\|reset\|error"
    done

### 3) Check ClientHello size (firewall may drop large ones)

    echo | openssl s_client -connect host:443 -msg 2>&1 | grep -A2 "ClientHello"

### 4) Test with minimal cipher list (smaller ClientHello)

    openssl s_client -connect host:443 -cipher 'ECDHE-RSA-AES128-GCM-SHA256' 2>&1

## Common Issues

    ❌ TLS 1.3 encrypted SNI/ESNI confuses old firewalls
    ❌ Large ClientHello (many ciphers/extensions) dropped
    ❌ MTU/fragmentation of TLS records
    ❌ IDS resets connections it can't inspect
    ❌ TLS 1.3 looks "different" — old IDS panics
    ❌ Post-quantum large handshakes exceed limits

## Fix

### 1) Reduce ClientHello size

Trim cipher suites and extensions to essentials

### 2) Address MTU issues

Lower MTU or enable MSS clamping on the firewall

    iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

### 3) Update firewall/IDS firmware

Old DPI engines don't understand TLS 1.3

### 4) Whitelist/bypass DPI for the endpoint

If firewall can't handle modern TLS, bypass inspection

### 5) Work with network team on TLS 1.3 support

Some enterprise firewalls need explicit TLS 1.3 config

