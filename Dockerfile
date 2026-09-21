# This Dockerfile builds a CTFd (https://github.com/CTFd/CTFd) image that
# enables TLS connectivity to Azure Database for MySQL.
# More info: https://learn.microsoft.com/en-us/azure/mysql/flexible-server/concepts-root-certificate-rotation
FROM ctfd/ctfd:3.7.0

USER root
RUN apt-get update && apt-get install -y wget openssl --no-install-recommends \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create certificates directory
RUN mkdir -p /opt/certificates/

# Download the certificates
RUN wget --user-agent="Mozilla" --progress=dot:giga https://cacerts.digicert.com/DigiCertGlobalRootCA.crt -P /opt/certificates/
RUN wget --user-agent="Mozilla" --progress=dot:giga https://cacerts.digicert.com/DigiCertGlobalRootG2.crt -P /opt/certificates/
RUN wget --user-agent="Mozilla" --progress=dot:giga "https://www.microsoft.com/pkiops/certs/Microsoft%20RSA%20Root%20Certificate%20Authority%202017.crt" -O /opt/certificates/Microsoft-RSA-Root-CA-2017.crt

# Convert certificates to PEM format
RUN openssl x509 -in /opt/certificates/DigiCertGlobalRootCA.crt -out /opt/certificates/DigiCertGlobalRootCA.crt.pem -outform PEM
RUN openssl x509 -in /opt/certificates/DigiCertGlobalRootG2.crt -out /opt/certificates/DigiCertGlobalRootG2.crt.pem -outform PEM
RUN openssl x509 -in /opt/certificates/Microsoft-RSA-Root-CA-2017.crt -out /opt/certificates/Microsoft-RSA-Root-CA-2017.crt.pem -outform PEM

# Combine all certificates into a single bundle file
RUN cat /opt/certificates/DigiCertGlobalRootCA.crt.pem \
        /opt/certificates/DigiCertGlobalRootG2.crt.pem \
        /opt/certificates/Microsoft-RSA-Root-CA-2017.crt.pem \
        > /opt/certificates/azure-mysql-ca-bundle.pem

# Clean up individual certificate files (optional)
RUN rm /opt/certificates/*.crt /opt/certificates/DigiCertGlobalRootCA.crt.pem \
       /opt/certificates/DigiCertGlobalRootG2.crt.pem \
       /opt/certificates/Microsoft-RSA-Root-CA-2017.crt.pem

USER 1001
EXPOSE 8000

ENTRYPOINT ["/opt/CTFd/docker-entrypoint.sh"]
