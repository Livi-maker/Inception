#!/bin/bash
set -e

# Crea la directory per il socket PHP-FPM se non esiste
mkdir -p /run/php

# Determina la versione di PHP dalla configurazione di sistema
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION;")

echo "sendmail_path = /bin/true" >> /etc/php/${PHP_VERSION}/cli/php.ini

# Funzione per generare wp-config.php il file di configurazione di WordPress
generate_wp_config() {
    echo "Generazione di wp-config.php..."

    cat > /var/www/html/wp-config.php << EOF
<?php
// Configurazione database
define('DB_NAME', 'database_mysql');
define('DB_USER', 'liv');
define('DB_PASSWORD', 'inception1');
define('DB_HOST', 'mariadb');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

// Chiavi di sicurezza ssl generate dinamicamente
define('AUTH_KEY',         '$(openssl rand -base64 32)');
define('SECURE_AUTH_KEY',  '$(openssl rand -base64 32)');
define('LOGGED_IN_KEY',    '$(openssl rand -base64 32)');
define('NONCE_KEY',        '$(openssl rand -base64 32)');
define('AUTH_SALT',        '$(openssl rand -base64 32)');
define('SECURE_AUTH_SALT', '$(openssl rand -base64 32)');
define('LOGGED_IN_SALT',   '$(openssl rand -base64 32)');
define('NONCE_SALT',       '$(openssl rand -base64 32)');

\$table_prefix = 'wp_';
define('WP_DEBUG', false);

// Forza HTTPS per l'admin
define('FORCE_SSL_ADMIN', true);

// URL e percorsi
define('WP_HOME', 'https://ldei-sva.42.fr');
define('WP_SITEURL', 'https://ldei-sva.42.fr');

//imposta absolut path nella cartella del file stesso
if ( !defined('ABSPATH') )
    define('ABSPATH', dirname(__FILE__) . '/');

// avvia wordpress
require_once(ABSPATH . 'wp-settings.php');
?>
EOF
}

# Genera il file wp-config.php sopra
generate_wp_config

# Imposta i permessi corretti
chown www-data:www-data /var/www/html/wp-config.php
chmod 644 /var/www/html/wp-config.php

# Installa WordPress se non già installato
if ! wp core is-installed --allow-root --path=/var/www/html; then
    echo "Installazione di WordPress..."
    wp core install \
        --url="https://ldei-sva.42.fr" \
        --title="wordpress_title" \
        --admin_user="wordpress_admin" \
        --admin_password="wordpress_password" \
        --admin_email="liviana.deisvaldi@gmail.com" \
        --allow-root \
        --path=/var/www/html
    echo "WordPress installato con successo!"
else
    echo "WordPress è già installato."
fi

# Crea un utente normale se non esiste
if ! wp user get "normal_user" --allow-root --path=/var/www/html > /dev/null 2>&1; then
    echo "Creazione dell'utente normale..."
    wp user create "normal_user" "mariorossi@gmail.com" \
        --user_pass="inception" \
        --role=author \
        --allow-root \
        --path=/var/www/html
    echo "Utente normale creato con successo!"
else
    echo "L'utente normale 'normal_user' esiste già."
fi

echo "Inizializzazione completata. Avvio PHP-FPM..."

# Avvia PHP-FPM in foreground usando il percorso completo
exec /usr/sbin/php-fpm${PHP_VERSION} -F
