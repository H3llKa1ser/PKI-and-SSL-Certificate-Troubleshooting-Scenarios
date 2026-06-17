# Scenario 59 - Certificate with Unicode / IDN Domain Issues

## Symptom

Internationalized domain (münchen.de, 北京.cn) cert fails

"hostname mismatch" despite correct domain

Cert shows punycode but browser shows Unicode

Email certs with international addresses fail

## Diagnostics

### 1) Check how the domain is encoded in the cert

    openssl x509 -in cert.crt -noout -text | grep -A2 "Subject Alternative Name"

IDN domains must be in PUNYCODE (ASCII) form in certs:

münchen.de → xn--mnchen-3ya.de

北京.cn    → xn--1lq90i.cn


### 2) Convert your domain to punycode to verify

Using idn2 tool:

    idn2 münchen.de

Output: xn--mnchen-3ya.de

### 3) Check what the browser/client sends

Browsers convert Unicode → punycode before TLS

    echo | openssl s_client -connect xn--mnchen-3ya.de:443 -servername xn--mnchen-3ya.de 2>/dev/null | openssl x509 -noout -text | grep DNS

## Fix

### 1) ALWAYS use punycode in certificate SANs

Request cert with:

    openssl req -new -key key.pem -out csr.pem -addext "subjectAltName=DNS:xn--mnchen-3ya.de"

NOT: DNS:münchen.de

### 2) Include both if needed

Some setups want the U-label too, but punycode is standard

### 3) For email (S/MIME) with IDN

Local part stays UTF-8, domain part → punycode

user@münchen.de → user@xn--mnchen-3ya.de in the cert

### 4) Verify SNI is sent in punycode

Configure clients to convert IDN → punycode before connecting
