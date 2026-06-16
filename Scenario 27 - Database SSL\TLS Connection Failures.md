# Scenario 27 - Database SSL/TLS Connection Failures

## Symptom

Application can't connect to database over SSL

PostgreSQL: "SSL connection has been closed unexpectedly"

MySQL: "SSL connection error: protocol version mismatch"

MongoDB: "SSL peer certificate validation failed"

## Diagnostics

### 1) PostgreSQL

Test SSL connection

    psql "host=db.company.com port=5432 dbname=mydb user=appuser sslmode=verify-full sslrootcert=ca.crt"

Is SSL on?

    psql -c "SHOW ssl;"

Active SSL connections

    psql -c "SELECT * FROM pg_stat_ssl;"

### 2) MySQL

Test SSL connection

    mysql --host=db.company.com --ssl-ca=ca.crt --ssl-mode=VERIFY_IDENTITY -u appuser -p

Is SSL on?

    mysql -e "SHOW VARIABLES LIKE '%ssl%';"

Active SSL connections

    mysql -e "SHOW STATUS LIKE 'Ssl_cipher';"

### 3) MongoDB

Test SSL connection

    mongosh "mongodb://db.company.com:27017" --tls --tlsCAFile ca.crt --tlsCertificateKeyFile client.pem

## SSL Mode Levels

    PostgreSQL sslmode options:
      disable      → No SSL ❌
      require      → SSL but NO cert verification ⚠️
      verify-ca    → Verify cert signed by trusted CA ✅
      verify-full  → Verify CA + hostname matches ✅✅ (most secure)
    
    MySQL ssl-mode options:
      DISABLED         → No SSL ❌
      PREFERRED        → SSL if available ⚠️
      REQUIRED         → SSL required, no cert check ⚠️
      VERIFY_CA        → Verify CA ✅
      VERIFY_IDENTITY  → Verify CA + hostname ✅✅

## Common Issues

    ❌ "private key file has group or world access"
       Fix: chmod 600 server.key
    
    ❌ Hostname mismatch with verify-full
       Fix: Ensure cert CN/SAN matches the DB hostname you connect to
    
    ❌ Self-signed cert rejected
       Fix: Add CA cert to client OR use proper CA-signed cert
    
    ❌ Old TLS version rejected
       Fix: Update both client and server to TLS 1.2+

## PostgreSQL Server Config fix

postgresql.conf

    ssl = on
    ssl_cert_file = '/etc/postgresql/server.crt'
    ssl_key_file = '/etc/postgresql/server.key'
    ssl_ca_file = '/etc/postgresql/ca.crt'
    ssl_min_protocol_version = 'TLSv1.2'
    
    # pg_hba.conf — Force SSL for connections
    # TYPE  DATABASE  USER  ADDRESS       METHOD
    hostssl all       all   0.0.0.0/0     scram-sha-256   # SSL required!
    
    # Set correct permissions on key
    chmod 600 /etc/postgresql/server.key
    chown postgres:postgres /etc/postgresql/server.key
        
