# This Dockerfile builds a CTFd (https://github.com/CTFd/CTFd) image that
# enables TLS connectivity to Azure Database for MySQL.
# More info: https://learn.microsoft.com/en-gb/azure/postgresql/flexible-server/concepts-networking-ssl-tls#downloading-root-ca-certificates-and-updating-application-clients-in-certificate-pinning-scenarios
FROM ctfd/ctfd:3.7.0

USER root
RUN apt-get update && apt-get install -y wget --no-install-recommends \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN wget --user-agent="Mozilla" --progress=dot:giga https://cacerts.digicert.com/DigiCertGlobalRootCA.crt -P /opt/certificates/
RUN openssl x509 -in /opt/certificates/DigiCertGlobalRootCA.crt -out /opt/certificates/DigiCertGlobalRootCA.crt.pem -outform PEM

USER 1001
EXPOSE 8000

ENTRYPOINT ["/opt/CTFd/docker-entrypoint.sh"]
