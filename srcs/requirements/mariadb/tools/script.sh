#!/bin/bash

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Inizializzazione del database MariaDB..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

echo "Avvio temporaneo di MariaDB..."
mysqld_safe --skip-networking --user=mysql --datadir=/var/lib/mysql &

echo "Attendo che MariaDB sia pronto..."
while ! mysqladmin ping --silent --user=root; do
    sleep 1
done
echo "MariaDB è pronto!"

echo "Forzo autenticazione root con password (richiesto dal subject)..."
if mysql -u root -e "SELECT 1;" >/dev/null 2>&1; then
    mysql -u root <<EOF
ALTER USER IF EXISTS 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES
EOF
elif mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1;" >/dev/null 2>&1; then
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
ALTER USER IF EXISTS 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
else
    echo "Errore: impossibile autenticarsi come root per configurare la password."
    exit 1
fi


if mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1;" >/dev/null 2>&1; then
    echo "MariaDB già configurato, aggiorno i permessi..."
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
-- Crea database se non esiste
CREATE DATABASE IF NOT EXISTS \`database_mysql\`;

-- Rimuovi utente esistente per ricrearlo
DROP USER IF EXISTS '${MYSQL_USER}'@'%';

-- Crea utente WordPress (% copre tutti gli host)
CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

-- Concedi privilegi
GRANT ALL PRIVILEGES ON \`database_mysql\`.* TO '${MYSQL_USER}'@'%';

FLUSH PRIVILEGES;
EOF

else
    echo "Primo setup di MariaDB..."
    mysql -u root <<EOF
-- Forza root a usare password (evita unix_socket)
ALTER USER IF EXISTS 'root'@'localhost' IDENTIFIED BY 'inception';

-- Crea database
CREATE DATABASE IF NOT EXISTS \`database_mysql\`;

-- Crea utente WordPress (% copre tutti gli host)
CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

-- Concedi privilegi
GRANT ALL PRIVILEGES ON \`database_mysql\`.* TO '${MYSQL_USER}'@'%';

-- Rimuovi account di default
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;

FLUSH PRIVILEGES;
EOF
fi

echo "MariaDB configurato e pronto!"

echo "Stop MariaDB..."
mysqladmin shutdown -u root -p "${MYSQL_ROOT_PASSWORD}"

echo "Avvio definitivo di MariaDB..."
exec mysqld --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0
