#!/bin/bash

# Inizializza database MariaDB
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Inizializzazione del database MariaDB..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# Avvia MariaDB temporaneamente per la configurazione
echo "Avvio temporaneo di MariaDB..."
mysqld_safe --skip-networking --user=mysql --datadir=/var/lib/mysql &

# Attendi che MariaDB sia pronto
echo "Attendo che MariaDB sia pronto..."
while ! mysqladmin ping --silent --user=root; do
    sleep 1
done
echo "MariaDB è pronto!"

# Forza autenticazione root a password (il plugin unix_socket permette login senza password)
echo "Forzo autenticazione root con password (richiesto dal subject)..."
if mysql -u root -e "SELECT 1;" >/dev/null 2>&1; then
    mysql -u root <<EOF
ALTER USER IF EXISTS 'root'@'localhost' IDENTIFIED BY 'inception';
FLUSH PRIVILEGES;
EOF
elif mysql -u root -p"inception" -e "SELECT 1;" >/dev/null 2>&1; then
    mysql -u root -p"inception" <<EOF
ALTER USER IF EXISTS 'root'@'localhost' IDENTIFIED BY 'inception';
FLUSH PRIVILEGES;
EOF
else
    echo "Errore: impossibile autenticarsi come root per configurare la password."
    exit 1
fi

# Configura database e utenti

# Se già configurato, aggiorna i permessi. Utile se fosse cambiato il .env
if mysql -u root -p"inception" -e "SELECT 1;" >/dev/null 2>&1; then
    echo "MariaDB già configurato, aggiorno i permessi..."
    mysql -u root -p"inception" <<EOF
-- Crea database se non esiste
CREATE DATABASE IF NOT EXISTS \`database_mysql\`;

-- Rimuovi utente esistente per ricrearlo
DROP USER IF EXISTS 'liv'@'%';

-- Crea utente WordPress (% copre tutti gli host)
CREATE USER 'liv'@'%' IDENTIFIED BY 'inception1';

-- Concedi privilegi
GRANT ALL PRIVILEGES ON \`database_mysql\`.* TO 'liv'@'%';

FLUSH PRIVILEGES;
EOF
# Se non configurato, setup iniziale
else
    echo "Primo setup di MariaDB..."
    mysql -u root <<EOF
-- Forza root a usare password (evita unix_socket)
ALTER USER IF EXISTS 'root'@'localhost' IDENTIFIED BY 'inception';

-- Crea database
CREATE DATABASE IF NOT EXISTS \`database_mysql\`;

-- Crea utente WordPress (% copre tutti gli host)
CREATE USER 'liv'@'%' IDENTIFIED BY 'inception1';

-- Concedi privilegi
GRANT ALL PRIVILEGES ON \`database_mysql\`.* TO 'liv'@'%';

-- Rimuovi account di default
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;

FLUSH PRIVILEGES;
EOF
fi

echo "MariaDB configurato e pronto!"

echo "Stop MariaDB..."
mysqladmin shutdown -u root -p"inception"

# Avvia MariaDB definitivo in foreground (PID 1)
echo "Avvio definitivo di MariaDB..."
exec mysqld --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0
