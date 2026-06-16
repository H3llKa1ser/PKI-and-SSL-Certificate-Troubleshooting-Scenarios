# Scenario 13: Java Application SSL Handshake Failure 

## Symptom

    javax.net.ssl.SSLHandshakeException:
      sun.security.validator.ValidatorException:
      PKIX path building failed:
      sun.security.provider.certpath.SunCertPathBuilderException:
      unable to find valid certification path to requested target

## Diagnostics

### 1) Check Java's truststore

Java has its OWN truststore separate from the OS!

    keytool -list -keystore $JAVA_HOME/lib/security/cacerts -storepass changeit | grep -i company

If company CA not found ← That's your problem!

### 2) Enable SSL debugging in Java

    java -Djavax.net.debug=ssl:handshake -jar your-app.jar 2>&1 | grep -E "trustStore|certificate"

### 3) Test with InstallCert tool or manually verify

    openssl s_client -connect api.company.com:443 -showcerts

#### Save the intermediate + root certs

## Fix

### Add CA to Java Truststore

Import your CA into Java's truststore

    keytool -import -alias company-root-ca -file company-root-ca.crt -keystore $JAVA_HOME/lib/security/cacerts -storepass changeit -noprompt

Verify it was added

    keytool -list -keystore $JAVA_HOME/lib/security/cacerts -storepass changeit -alias company-root-ca

Restart your Java application

#### Alternative: Use custom truststore (better for containers)

    keytool -import -alias company-root-ca -file company-root-ca.crt -keystore custom-truststore.jks -storepass yourpassword -noprompt

Pass to Java app

    java -Djavax.net.ssl.trustStore=custom-truststore.jks -Djavax.net.ssl.trustStorePassword=yourpassword -jar your-app.jar

### Spring Boot Application

application.yml

    server:
      ssl:
        trust-store: classpath:custom-truststore.jks
        trust-store-password: yourpassword
        trust-store-type: JKS
        key-store: classpath:keystore.p12
        key-store-password: yourpassword
        key-store-type: PKCS12

