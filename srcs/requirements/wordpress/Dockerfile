FROM debian:11-slim

RUN apt-get update && apt-get install -y \
    php-fpm \
    php-mysql \
    php-curl \
    php-gd \
    php-mbstring \
    php-xml \
    php-zip \
    php-json \
    php-intl \
    default-mysql-client \
    wget \
    unzip \
    curl \
    openssl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    php wp-cli.phar --info && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

COPY ./conf/www.conf /tmp/www.conf

WORKDIR /var/www/html

RUN wget -O /tmp/latest.tar.gz https://wordpress.org/latest.tar.gz && \
    tar -xzf /tmp/latest.tar.gz -C /tmp && \
    mv /tmp/wordpress/* /var/www/html/ && \
    rm -rf /var/www/html/index.html && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html && \
    rm -f /tmp/latest.tar.gz

COPY ./tools/wordpress.sh /usr/local/bin/wordpress.sh
RUN chmod +x /usr/local/bin/wordpress.sh

EXPOSE 9000

RUN PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION;") && \
    mkdir -p /etc/php/${PHP_VERSION}/fpm/pool.d && \
    cp /tmp/www.conf /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

CMD ["/usr/local/bin/wordpress.sh"]