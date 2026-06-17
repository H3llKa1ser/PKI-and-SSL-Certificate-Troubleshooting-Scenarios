# Scenario 70 - Certificate Issue with Containerized App Missing CA Bundle

## Symptom

App works on host, fails in container

"x509: certificate signed by unknown authority"

Minimal/scratch/distroless images have NO CA certs!

Alpine container can't verify ANY public cert

## Diagnostics

### 1) Check if CA bundle exists in container

    docker exec mycontainer ls -la /etc/ssl/certs/
    docker exec mycontainer cat /etc/ssl/certs/ca-certificates.crt | wc -l

Empty or missing → no CA bundle!

### 2) Check image base

    docker inspect myimage | grep -i "from\|base"

scratch, distroless, minimal alpine = often no CA certs

### 3) Test verification inside container

    docker exec mycontainer wget -q https://google.com -O /dev/null && echo OK || echo FAIL

## Fix

### 1) Alpine - inctall ca-certificates

    FROM alpine:3.19
    RUN apk add --no-cache ca-certificates
    RUN update-ca-certificates

### 2) Debian/Ubuntu slim

    FROM debian:bookworm-slim
    RUN apt-get update && \
        apt-get install -y --no-install-recommends ca-certificates && \
        rm -rf /var/lib/apt/lists/*

### 3) Distroless - already includes CA certs in most variants

    FROM gcr.io/distroless/base-debian12

CA certs are at /etc/ssl/certs/ca-certificates.crt

### 4) Scratch - copy CA bundle from a build stage

    FROM alpine:3.19 AS certs
    RUN apk add --no-cache ca-certificates
    
    FROM scratch
    COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
    COPY myapp /myapp
    ENTRYPOINT ["/myapp"]
