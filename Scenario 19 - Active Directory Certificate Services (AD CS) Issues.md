# Scenario 19 - Active Directory Certificate Services (AD CS) Issues

## Symptom

Windows domain users cannot auto-enroll for certificates

Error: 

    "The RPC server is unavailable"

Error: 

    "The revocation function was unable to check revocation"

Certificate templates not showing up in enrollment wizard

Smart card login suddenly failing

## Diagnostics

### 1) Check CA service is running

    Get-Service -Name CertSvc

Status should be: Running ✅

### 2) Check CA health

Ping the CA

    certutil -ping

Get CA information

    certutil -CAInfo

Publish CRL manually

    certutil -CRL

### 3) Check CRL validity

    certutil -URL https://pki.company.com/crl/company-ca.crl

Look for: Verified ✅ or ERROR ❌

### 4) Check certificate template permissions

    # In MMC → Certificate Templates
    # Right-click template → Properties → Security
    # Ensure "Domain Computers" or "Domain Users" has:
    #   Read ✅
    #   Enroll ✅
    #   Autoenroll ✅

### 5) Check auto-enrollment GPO

Check applied GPOs

    gpresult /h gpresult.html

Look for: Certificate Services Client - Auto-Enrollment

## Fixes and Issues

### 1) CRL is expired or unreachable

Fix: Publish new CRL

    certutil -CRL

Verify CRL is accessible

    certutil -URL http://pki.company.com/crl/company-ca.crl

### 2) Auto-enrollment not working

Force group policy update

    gpupdate /force

Force certificate enrollment

    certutil -pulse

### 3) Certificate template not visible

In CA console → Certificate Templates → New → Certificate Template to Issue

Add the template you need

### 4) Check DCOM/RPC connectivity

RPC Endpoint Mapper

    Test-NetConnection -ComputerName CA-SERVER -Port 135

SMB

    Test-NetConnection -ComputerName CA-SERVER -Port 445

### 5) View pending requests

View pending requests

    certutil -view -restrict "Disposition=9"

Approve pending request

    certutil -resubmit REQUEST_ID

