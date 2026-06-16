# Scenario 16 - HSM Integration Failure

## Symptom

Application cannot access private key stored in HSM

Error: 

    "PKCS#11 token not found"

Error: 

    "CKR_TOKEN_NOT_PRESENT"

Error: 

    "Failed to initialize HSM connection"

Web server fails to start after HSM key migration

## Diagnostics

### 1) Check HSM connectivity

List available PKCS#11 slots

    pkcs11-tool --module /usr/lib/libpkcs11.so --list-slots

#### Output if working:

    Slot 0 (0x0): HSM Virtual Slot
      token label        : MyHSM
      token manufacturer : Thales
      token model        : Luna K7
      token flags        : login required ✅

#### Output if broken:

    No slots present ❌

### 2) List objects in HSM

    pkcs11-tool --module /usr/lib/libpkcs11.so --login --pin 1234 --list-objects

#### Should show your keys and certificates:

    Private Key Object; RSA
      label:      webserver-key
      ID:         01
      Usage:      sign, decrypt ✅

### 3) Test key operation

    pkcs11-tool --module /usr/lib/libpkcs11.so --login --pin 1234 --sign --id 01 --mechanism RSA-PKCS --input-file test.txt --output-file test.sig

### 4) Check application HSM config

Test OpenSSL PKCS#11 engine

    openssl engine pkcs11 -t

## Fix

### Nginx with HSM (PKCS#11)

    # nginx.conf with HSM key
    ssl_certificate     /etc/ssl/server.crt;    # Cert stored normally
    
    # Private key stored in HSM via PKCS#11 URI
    ssl_certificate_key "engine:pkcs11:pkcs11:token=MyHSM;object=webserver-key;pin-value=1234";
    
    # Load the PKCS#11 engine
    ssl_engine pkcs11;

## More issues and fixes

### 1) HSM PIN locked after failed attempts

Fix: Reset PIN using SO (Security Officer) credentials

    pkcs11-tool --module libpkcs11.so --login --login-type so --so-pin SOPIN --init-pin --new-pin NEWPIN

### 2) HSM driver/library not found

Fix: Verify PKCS#11 library path

    ls -la /usr/lib/libpkcs11.so
    export PKCS11_MODULE_PATH=/usr/lib/libpkcs11.so
   
### 3) HSM network connection timeout (network HSM)

Fix: Check network connectivity and firewall

    telnet hsm.company.com 1792

### 4) Wrong slot/token selected

Fix: List all slots and use correct slot ID

    pkcs11-tool --list-slots --list-token-slots
   
