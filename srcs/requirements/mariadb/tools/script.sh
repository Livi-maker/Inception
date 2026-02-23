#!/bin/bash

# Leggi i secrets dai file
export MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_admin_password)
export MYSQL_DATABASE=$(cat /run/secrets/db_name)
export MYSQL_USER=$(cat /run/secrets/db_user)
export MYSQL_PASSWORD=$(cat /run/secrets/db_password)

echo "{$MYSQL_ROOT_PASSWORD}"
echo "{$MYSQL_DATABASE}"

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
-- Forza root a usare password (evita unix_socket)
ALTER USER IF EXISTS 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

elif mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1;" >/dev/null 2>&1; then
    echo "MariaDB già configurato, aggiorno i permessi..."
else
    exit 1
fi

mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
-- Crea database se non esiste
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

-- Rimuovi utente esistente per ricrearlo
DROP USER IF EXISTS '${MYSQL_USER}'@'%';

-- Crea utente WordPress (% copre tutti gli host)
CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

-- Concedi privilegi
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

-- Rimuovi account di default
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;

FLUSH PRIVILEGES;
EOF

echo "MariaDB configurato e pronto!"

# Debug: mostra gli utenti creati
echo "Debug - Utenti MariaDB:"
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT User, Host FROM mysql.user WHERE User='${MYSQL_USER}' OR User='root';" 2>/dev/null || echo "Debug fallito - continuo..."

echo "Stop MariaDB..."
mysqladmin shutdown -u root -p"${MYSQL_ROOT_PASSWORD}"

echo "Avvio definitivo di MariaDB..."
exec mysqld --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0
