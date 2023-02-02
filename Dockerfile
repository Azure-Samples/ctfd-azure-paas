# This Dockerfile builds a CTFd (https://github.com/CTFd/CTFd) image that
# enables TLS connectivity to Azure Database for MariaDB.
# More info: https://learn.microsoft.com/en-us/azure/mariadb/concepts-ssl-connection-security
FROM ctfd/ctfd:3.5.1

USER root
RUN apt-get update && apt-get install -y wget=1.20.3 --no-install-recommends \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
RUN wget --progress=dot:giga https://www.digicert.com/CACerts/BaltimoreCyberTrustRoot.crt.pem -P /opt/certificates/

USER 1001
EXPOSE 8000
ENTRYPOINT ["/opt/CTFd/docker-entrypoint.sh"]
