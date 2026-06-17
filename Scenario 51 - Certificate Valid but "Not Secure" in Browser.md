# Scenario 51 - Certificate Valid but "Not Secure" in Browser

## Symptom

Certificate is valid, trusted, not expired ✅

But browser STILL shows "Not Secure" or no padlock!

Mixed content warnings

Padlock with a warning triangle

## Diagnostics

This is usually NOT a cert problem — it's MIXED CONTENT!

### 1) Check for HTTP resources on HTTPS page

Open browser DevTools → Console

Look for: 

    "Mixed Content: The page was loaded over HTTPS, but requested an insecure resource"

### 2) Scan the page for http:// references

    curl -s https://yoursite.com | grep -oE "http://[^\"']*" | sort -u

### 3) Check for insecure resources

    # - <img src="http://...">
    # - <script src="http://...">
    # - <link href="http://...">
    # - CSS background-image: url(http://...)
    # - AJAX/fetch to http:// endpoints

## Types of Mixed Content

    🟡 Mixed Passive Content (images, audio, video):
       - Browser loads it but shows warning
       - Padlock with warning
    
    🔴 Mixed Active Content (scripts, CSS, iframes, XHR):
       - Browser BLOCKS it entirely!
       - Page may break completely
       - "Not Secure" indicator

## Fix

### 1) Use protocol-relative or HTTPS URLs

    <!-- BAD -->
    <script src="http://cdn.example.com/lib.js"></script>
    <!-- GOOD -->
    <script src="https://cdn.example.com/lib.js"></script>

### 2) Add Content-Security-Policy to auto-upgrade

    add_header Content-Security-Policy "upgrade-insecure-requests";

This tells the browser to upgrade all http:// to https:// automatically

### 3) Redirect all HTTP to HTTPS

    server {
        listen 80;
        server_name yoursite.com;
        return 301 https://$host$request_uri;
    }

### 4) Add HSTS to enforce HTTPS

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

### 5) Update API calls to HTTPS

    // BAD
    fetch('http://api.example.com/data')
    // GOOD
    fetch('https://api.example.com/data')

## Prevention

□ Use HTTPS for ALL resources (CDN, fonts, APIs, images)

□ Add "upgrade-insecure-requests" CSP header

□ Use relative URLs where possible (/path not http://...)

□ Scan with tools like "Why No Padlock?" before launch

□ Enable HSTS to force HTTPS everywhere
