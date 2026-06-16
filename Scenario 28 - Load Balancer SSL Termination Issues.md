# Scenario 28 - Load Balancer SSL Termination Issues

## Symptom

SSL works at load balancer but backend gets confused

App thinks it's HTTP when it's actually HTTPS

Redirect loops (https → http → https → ...)

"Mixed content" warnings in browser

Backend can't determine the original client protocol

## SSL Termination

    SSL Termination at Load Balancer:
    Client ──HTTPS──► [Load Balancer] ──HTTP──► [Backend]
            encrypted              decrypted!
    
    The backend sees HTTP — but the user used HTTPS!
    This causes redirect loops & mixed content. ⚠️

## Diagnostics

### 1) Check what protocol the backend uses

Add a debug endpoint that prints headers

    curl -H "X-Debug: true" https://yoursite.com/debug

Look for these headers from the LB

    X-Forwarded-Proto: https      ← Should be present!
    X-Forwarded-For: 1.2.3.4
    X-Forwarded-Port: 443

#### If X-Forwarded-Proto missing → backend can't detect HTTPS!

### 2) Check for redirect loops

    curl -v -L https://yoursite.com 2>&1 | grep -i "location:"

#### If you see endless redirects → redirect loop confirmed!

## Fix

### 1) Backend Awarenes (Nginx behind LB)

    # Tell Nginx to trust the X-Forwarded-Proto header
    server {
        listen 80;
    
        # Detect original protocol from load balancer
        set $forwarded_scheme $scheme;
        if ($http_x_forwarded_proto = "https") {
            set $forwarded_scheme "https";
        }
    
        # Only redirect to HTTPS if NOT already HTTPS at the LB
        if ($http_x_forwarded_proto != "https") {
            return 301 https://$host$request_uri;
        }
    }

### 2) Application Frameworks

Python

    # Flask
    from werkzeug.middleware.proxy_fix import ProxyFix
    app.wsgi_app = ProxyFix(app.wsgi_app, x_proto=1, x_host=1)

Ruby

    # Rails (config/environments/production.rb)
    config.force_ssl = true
    config.action_dispatch.trusted_proxies = [IPAddr.new('10.0.0.0/8')]

JavaScript

    // Express.js
    app.set('trust proxy', true);  // Trust X-Forwarded-* headers

### 3) AWS ALB Configuration

ALB automatically adds:

    X-Forwarded-Proto
    X-Forwarded-For
    X-Forwarded-Port

Just configure your backend to TRUST and READ these headers!
