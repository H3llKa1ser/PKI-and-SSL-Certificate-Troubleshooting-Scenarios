# Scenario 76 - Certificate Rotation Breaks Cached JWT / Token Signing

## Symptom

Rotated the signing certificate/key

All existing JWTs/tokens suddenly invalid!

"signature verification failed"

Users logged out en masse

SSO/OAuth tokens rejected after key rotation

## Diagnostics

### 1) Understand JWT signing relationship

JWTs are signed with a private key

Verified with the corresponding public key (often via JWKS)

Rotate the key → old tokens can't be verified!

### 2) Check the JWKS endpoint

    curl https://auth.company.com/.well-known/jwks.json | jq

Does it include BOTH old and new keys (by kid)?

    {"keys": [{"kid": "old-key", ...}, {"kid": "new-key", ...}]}

### 3) Check token header for key ID

    echo "$JWT" | cut -d. -f1 | base64 -d | jq

    {"alg": "RS256", "kid": "old-key"}  ← Which key signed it?

## Fix

### Graceful Key Rotation for JWT

✅ CORRECT JWT key rotation (overlap):

    Phase 1: Publish BOTH keys in JWKS
       JWKS = [old-key, new-key]
       Still SIGN with old-key
    
    Phase 2: Switch signing to new-key
       JWKS = [old-key, new-key]   ← Both still published!
       Now SIGN with new-key
       Old tokens still verify (old-key in JWKS)
    
    Phase 3: After all old tokens expire
       JWKS = [new-key]            ← Remove old key
       Old tokens are gone anyway

Result: Zero disruption!

### Python implementation example

    # Implementation — include kid and support multiple keys
    import jwt
    from jwt import PyJWKClient
    
    # Sign with kid
    token = jwt.encode(
        payload,
        new_private_key,
        algorithm="RS256",
        headers={"kid": "new-key-2026"}    # Identify the key!
    )
    
    # Verify — fetch correct key by kid from JWKS
    jwks_client = PyJWKClient("https://auth.company.com/.well-known/jwks.json")
    signing_key = jwks_client.get_signing_key_from_jwt(token)
    decoded = jwt.decode(token, signing_key.key, algorithms=["RS256"])

## Prevention

□ ALWAYS use "kid" (key ID) in JWT headers

□ Publish multiple keys in JWKS during rotation

□ Keep old key until ALL tokens signed with it expire

□ Overlap window = max token lifetime + buffer

□ Automate JWKS updates with key rotation

