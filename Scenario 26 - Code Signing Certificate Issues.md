# Scenario 26 - Code Signing Certificate Issues.md

## Symptom

Windows: "Unknown Publisher" warning on your software

"This app can't run on your PC"

SmartScreen blocks your installer

macOS: "App is damaged and can't be opened"

Driver signature verification failed

## Diagnostics

### 1) Windows: Check signature on your executable

    signtool verify /pa /v yourapp.exe

#### Output if good:

    Successfully verified: yourapp.exe ✅

#### Output if bad:

    SignTool Error: A certificate chain processed, but terminated in a root certificate which is not trusted ❌

### 2) Check the signing certificate

    Get-AuthenticodeSignature yourapp.exe | Format-List

### 3) Check timestamp (CRITICAL for code signing!)

    signtool verify /pa /v /tw yourapp.exe

## Common Issues

    ❌ Certificate expired AND no timestamp
       (Timestamp lets signature remain valid AFTER cert expires!)
    
    ❌ Using standard cert instead of EV cert
       (EV certs build SmartScreen reputation instantly)
    
    ❌ Not timestamping the signature
       (Without timestamp: signature dies when cert expires!)
    
    ❌ Wrong Extended Key Usage (missing Code Signing)

## Fix (Windows)

### 1) ALWAYS timestamp your signatures!

    signtool sign /fd SHA256 `
      /a `
      /tr http://timestamp.digicert.com `   # ← Timestamp server!
      /td SHA256 `
      yourapp.exe

#### Why timestamping matters:

Without timestamp: Cert expires 2026 → ALL signatures invalid 2026

With timestamp:    Cert expires 2026 → signatures stay valid forever! (proves signing happened while cert was valid)

### 2) Use EV Code Signing Certificate

#### EV certs:

 - Build SmartScreen reputation faster

 - Required for kernel-mode drivers
 
 - Stored on hardware token (USB/HSM)

### 3) Sign with HSM-stored EV cert

    signtool sign /fd SHA256 /sha1 <cert-thumbprint> /tr http://timestamp.digicert.com /td SHA256 yourapp.exe

## Fix (macOS Code Signing)

### 1) Sign macOS app

    codesign --sign "Developer ID Application: Company" \
      --timestamp \                    # ← Always timestamp!
      --options runtime \
      YourApp.app

### 2) Verify

    codesign --verify --verbose YourApp.app
    spctl --assess --verbose YourApp.app   # Check Gatekeeper

### 3) Notarize (required for macOS 10.15+!)

    xcrun notarytool submit YourApp.zip --apple-id you@company.com --team-id TEAMID --wait

