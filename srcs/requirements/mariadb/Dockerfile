FROM debian:11-slim 

RUN apt-get update && \
    apt-get install -y mariadb-server mariadb-client && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY ./tools/script.sh /usr/local/bin/script.sh

RUN chmod +x /usr/local/bin/script.sh

RUN mkdir -p /var/lib/mysql && chown -R mysql:mysql /var/lib/mysql

EXPOSE 3306

CMD ["/usr/local/bin/script.sh"]