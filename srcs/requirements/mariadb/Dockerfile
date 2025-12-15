FROM debian:11-slim 

WORKDIR /conf

RUN apt-get update && \
    apt-get install -y mariadb-server mariadb-client && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/lib/mysql/my.cnf && chown -R mysql:mysql /var/lib/mysql

EXPOSE 3306

CMD ["mysqld"] 
