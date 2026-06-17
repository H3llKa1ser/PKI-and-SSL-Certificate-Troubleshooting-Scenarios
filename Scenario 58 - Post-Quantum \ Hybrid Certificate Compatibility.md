# Scenario 58 - Post-Quantum / Hybrid Certificate Compatibility

## Symptom

New hybrid PQC certificates deployed

Older clients fail: "unsupported certificate"

Handshake size too large, connection drops

"TLS record overflow"

Some middleboxes drop large ClientHello messages

## Diagnostics

### 1) Check if cert uses post-quantum algorithms

    openssl x509 -in cert.crt -noout -text | grep "Signature Algorithm"

Look for:

    dilithium, falcon, sphincs+, kyber, ML-KEM, ML-DSA

### 2) Check handshake size (PQC = much larger!)

    openssl s_client -connect host:443 -msg 2>&1 | grep -i "ClientHello"

PQC handshakes can exceed traditional MTU limits

### 3) Test with hybrid key exchange

    openssl s_client -connect host:443 -groups x25519_kyber768 2>&1

## Understanding Post-Quantum Cryptography

    Post-Quantum Cryptography (PQC):
    - Protects against future quantum computers
    - BUT signatures/keys are MUCH larger
      RSA-2048 signature: ~256 bytes
      Dilithium signature: ~2,400+ bytes!
    - Larger handshakes break old middleboxes
    - Not all clients support it yet

## Fix

### 1) Use hybrid approach (classical + PQC)

Provides both quantum resistance AND backward compatibility

#### x25519_kyber768 = classical X25519 + PQC Kyber

### 2) Serve dual certificates during transition

PQC-capable clients → hybrid cert

Legacy clients → traditional cert

### 3) Address middlebox issues

Some firewalls drop ClientHello > 1500 bytes

Work with network team to allow larger handshakes

### 4) Stay on classical for now if not ready

PQC is still maturing — assess your actual quantum risk timeline
