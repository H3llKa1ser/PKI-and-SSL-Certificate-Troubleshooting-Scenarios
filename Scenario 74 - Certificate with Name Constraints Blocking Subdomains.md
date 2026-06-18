# Scenario 74 - Certificate with Name Constraints Blocking Subdomains

## Symptom

Intermediate CA can't issue for certain domains

"certificate signature failure"

"permitted subtree violation"

Internal CA suddenly can't issue for a domain it should

Name Constraints in CA cert blocking issuance

## Diagnostics

### 1) Check the CA cert for Name Constraints

    openssl x509 -in intermediate-ca.crt -noout -text | grep -A10 "Name Constraints"

#### Output example:

    # X509v3 Name Constraints: critical
    #     Permitted:
    #       DNS:.company.com          ← Can ONLY issue for *.company.com!
    #     Excluded:
    #       DNS:.secret.company.com   ← But NOT secret.company.com!

### 2) Check what domain you are trying to issue

Does it fall outside the permitted subtree?

Or inside an excluded subtree?

### 3) Verify the full constraint chain

Constraints can be at ANY level of the CA hierarchy

## Name Constraints Explanation

Name Constraints LIMIT what a CA can issue:

Permitted: DNS:.company.com

  → CA can ONLY issue for company.com subdomains

Excluded: DNS:.internal.company.com

  → CA can issue for company.com EXCEPT internal subdomain

This is a SECURITY FEATURE (limits CA blast radius)

But it can block legitimate issuance if misconfigured!

## Fix

### 1) Understand why the constraint exists

It's protecting against the CA issuing rogue certs

### 2) If legitimately needed, reissue CA with correct constraints

    cat > ca-constraints.cnf << 'EOF'
    [v3_ca]
    basicConstraints = critical, CA:TRUE
    nameConstraints = critical, @name_constraints
    
    [name_constraints]
    permitted;DNS.0 = company.com
    permitted;DNS.1 = company.org      # Add the newly needed domain
    excluded;DNS.0 = secret.company.com
    EOF

Then,

    openssl x509 -req -in ca.csr -CA root.crt -CAkey root.key -extfile ca-constraints.cnf -extensions v3_ca -out new-intermediate-ca.crt

### 3) Use a different CA for the out-of-scope domain

If the constraint is correct, use the right CA instead
