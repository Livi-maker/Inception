FROM debian:11-slim

RUN apt-get update && apt-get install -y ngnix && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY ./conf/nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /etc/nginx/ssl && \
    apt-get update && \
    apt-get install -y openssl && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/smarinel.42.fr.key \
    -out /etc/nginx/ssl/ldei-sva.42.fr.crt \
    -subj "/C=IT/ST=Lazio/L=Rome/O=42/OU=Student/CN=ldei-sva.42.fr" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]