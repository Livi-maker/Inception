# Inception - Guida al Progetto

> Nota: il subject richiede di consegnare un README dedicato con le spiegazioni richieste dal progetto. Questo file, invece, è una guida operativa per realizzare e testare l'infrastruttura; non sostituisce il README da consegnare.

## Sommario

1. [Prerequisiti](#prerequisiti)
2. [Struttura del Progetto](#struttura-del-progetto)
3. [Teoria Dietro il Progetto](#teoria-dietro-il-progetto)
4. [Ordine di Avvio dei Container](#ordine-di-avvio-dei-container)
5. [Sviluppo Step-by-Step: Prima di Iniziare](#sviluppo-step-by-step-prima-di-iniziare)
6. [Sviluppo Step-by-Step: MariaDB](#sviluppo-step-by-step-mariadb-primo-passo)
7. [Sviluppo Step-by-Step: WordPress](#sviluppo-step-by-step-wordpress-secondo-passo)
8. [Sviluppo Step-by-Step: NGINX](#sviluppo-step-by-step-nginx-terzo-passo)
9. [Sviluppo Step-by-Step: docker-compose.yml](#sviluppo-step-by-step-docker-composeyml-quarto-passo)
10. [Sviluppo Step-by-Step: Makefile](#sviluppo-step-by-step-makefile-quinto-passo)
11. [Comandi Utili per Debug](#comandi-utili-per-debug)
12. [Volumi Persistenti](#volumi-persistenti)
13. [Rete Docker](#rete-docker)

---

## Prerequisiti

**Configurazione iniziale del dominio:**

OBBLIGATORIO:
1. Aggiungi al file `/etc/hosts` una riga con il tuo nome intra (es. `127.0.0.1 tuo-login-intra.42.fr`) per risolvere il dominio personalizzato.

(OPZIONALI) SE USI QUESTA REPO GIÀ CONFIGURATA:

2. In `srcs/.env` imposta `NOME_INTRA=tuo-login-intra` (verrà usato da NGINX e WordPress).
3. Per questioni di comodità, nei file `srcs/requirements/nginx/conf/nginx.conf` e `srcs/requirements/nginx/Dockerfile` la variabile `${DOMAIN_NAME}` è hardcodata 3 volte ciascuno, sostituisci `smarinel.42.fr` con `tuo-login-intra.42.fr` per usare il tuo dominio personalizzato.

---

## Struttura del Progetto

```
inception/
├── Makefile                    # Comandi make
├── README.md                   # Diverso da questa guida
├── USER_DOC.md
├── DEV_DOC.md
└── srcs/
    ├── .env                    # Variabili d'ambiente (NON committare!)
    ├── docker-compose.yml      # Orchestrazione containers
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   └── tools/
        │       └── setup-mariadb.sh
        ├── nginx/
        │   ├── Dockerfile
        │   └── conf/
        │       └── nginx.conf
        └── wordpress/
            ├── Dockerfile
            ├── conf/
            │   └── www.conf    # Config PHP-FPM
            └── tools/
                └── init-wordpress.sh
```

---

## Teoria Dietro il Progetto

### Ruolo di `docker compose` come orchestratore

`docker compose` è uno strumento per definire e gestire applicazioni Docker composte da più container. Utilizzando un file `docker-compose.yml`, è possibile specificare i vari servizi (container), le loro immagini, le reti e i volumi necessari. Con `docker compose up`, è possibile avviare e collegare tutti i container definiti nel file, semplificando la gestione di applicazioni complesse. Inoltre, il file `docker-compose.yml` utilizza variabili definite nel file `.env`, creando variabili globali che possono essere referenziate all'interno della configurazione.

### Struttura a 3 componenti: Dockerfile, conf, script

I servizi nel progetto sono suddivisi in tre componenti principali:
1. **Dockerfile**: definisce l'immagine del container, specificando la base da cui partire e le modifiche da apportare (es. installazione di pacchetti, copia di file).
2. **conf**: file di configurazione necessario per il servizio. Ad esempio, per NGINX, qui troviamo il file `nginx.conf` che definisce le impostazioni del server web.
3. **script**: script di inizializzazione per la configurazione del servizio. Ad esempio, `setup-mariadb.sh` per MariaDB imposta il database e gli utenti iniziali, mentre `init-wordpress.sh` avvia PHP-FPM come processo principale (PID 1). Secondo il subject, è obbligatorio che il servizio principale del container sia avviato con `CMD` (o `exec` o `ENTRYPOINT`) e diventi PID 1 per gestire correttamente i segnali di terminazione.

### Flusso dall'avvio al processo principale

Quando si avvia un container, Docker esegue i seguenti passaggi:
1. Legge il `Dockerfile` per costruire l'immagine del container, se non è già presente.
2. Avvia il container da questa immagine.
3. Esegue eventuali script di avvio definiti (es. `init-wordpress.sh`).
4. Espone le porte necessarie e collega il container alla rete definita.
5. Il processo principale del container (es. il server web o il database) viene avviato e inizia a ricevere richieste.

### Perché `exec` è fondamentale

Nel contesto Docker, exec serve a sostituire lo script di avvio (PID 1) con il vero processo del servizio (es. mysqld, php-fpm). Questo è necessario quando uno script prepara l’ambiente (come per MariaDB e WordPress): alla fine dello script, usiamo exec affinché il processo principale del container sia proprio mysqld o php-fpm, così Docker può gestire correttamente segnali e riavvii. (Per NGINX, invece, il processo viene avviato direttamente dal Dockerfile con CMD).

---

## Ordine di Avvio dei Container

### Sequenza di avvio

```
1. mariadb     →  2. wordpress     →  3. nginx
```

| Container     | Dipendenze        | Motivo                                      |
|---------------|-------------------|---------------------------------------------|
| **mariadb**   | Nessuna           | Database deve essere pronto per primo       |
| **wordpress** | mariadb (healthy) | PHP necessita del DB per installare WP      |
| **nginx**     | wordpress         | Proxy verso PHP-FPM che deve essere attivo  |

### Meccanismo di dipendenza

```yaml
# docker-compose.yml

wordpress:
  depends_on:
    mariadb:
      condition: service_healthy  # Aspetta healthcheck OK

nginx:
  depends_on:
    - wordpress  # Aspetta solo che il container parta
```

**Differenza importante:**
- `condition: service_healthy` → Aspetta che l'healthcheck passi.
- Senza condition → Aspetta solo che il container sia "running".

---

## Sviluppo Step-by-Step: Prima di Iniziare

> Nota IMPORTANTE: prima di iniziare gli step, leggi la sezione **Pulizia COMPLETA** piu in basso. Durante lo sviluppo e i test è molto facile avere residui (volumi/dati/immagini) che falsano i risultati: se qualcosa non torna, fai prima pulizia completa e riparti.

> Nota sulle variabili: idealmente le credenziali/variabili dovrebbero stare nel file `srcs/.env` (e rimanere segrete), ma per usarle correttamente serve `docker-compose.yml` o riscriverle manualmente ad ogni comando. Ora hai due opzioni: (1) creare `docker-compose.yml` prima per poter usare subito `.env`, oppure come in questa guida (2) tenere temporaneamente alcuni valori hardcoded durante i primi test e spostarli nel `.env` quando introduci `docker-compose.yml`.

> Scelta della Versione OS: Usa Debian nella penultima versione stabile.

> Suggerimento: i file sono commentati riga per riga direttamente al loro interno per spiegare comandi e parametri.

---

## Sviluppo Step-by-Step: MariaDB (primo passo)

### 1. Inizia da MariaDB

Il primo container da creare è **MariaDB**, perché tutti gli altri servizi dipendono dal database, dovrai creare un **Dockerfile** che prepara l'immagine e uno **script di inizializzazione** che configura il database e avvia il servizio.

#### Dockerfile di MariaDB

Il [requirements/mariadb/Dockerfile](srcs/requirements/mariadb/Dockerfile) costruisce l'immagine:

* Installa MariaDB server e client
* Copia lo script di setup (`setup-mariadb.sh`)
* Prepara la directory dati
* Imposta il comando di avvio

#### Script di setup (`setup-mariadb.sh`)

Lo script [requirements/mariadb/tools/setup-mariadb.sh](srcs/requirements/mariadb/tools/setup-mariadb.sh) viene eseguito come processo principale (PID 1) del container:

* Inizializza il database se necessario
* Avvia MariaDB temporaneamente per la configurazione
* Crea il database e l’utente WordPress
* Applica permessi e password
* Termina il MariaDB temporaneo e avvia il vero servizio con `exec mysqld ...` (così `mysqld` diventa PID 1)

### Test Container MariaDB

Una volta configurato, verifica il funzionamento isolato:

```bash
# Crea la rete Docker per ora superflua ma servirà dopo per WordPress e NGINX
docker network create wordpress_network 2>/dev/null || true

# Avvia solo MariaDB
# Per questo test rapido usiamo un volume standard (mariadb_data) per comodità. Nel docker-compose.yml sarà obbligatorio usare il percorso fisico (/home/tuo-login/data/mariadb) come da subject.
docker build -f srcs/requirements/mariadb/Dockerfile -t mariadb srcs/requirements/mariadb && docker run -d --name mariadb --network wordpress_network -v mariadb_data:/var/lib/mysql mariadb
```

**Test SQL e utenti creati:**

```bash
# Verifica connessione
docker exec -it mariadb mysqladmin ping -u root -p

# Accedi al database come root e necessariamente dovresti inserire la password
docker exec -it mariadb mysql -u root -p
#dovrebbe fallire senza password
docker exec -it mariadb mysql -u root

# Verifica utente WordPress
docker exec -it mariadb mysql -u normal_user -p wordpress_db
```

**Cosa verificare:**

* [ ] Container avviato senza errori
* [ ] Database `wordpress_db` creato
* [ ] Utente `normal_user` può accedere
* [ ] Healthcheck passa: `docker ps` mostra "(healthy)"

---

## Sviluppo Step-by-Step: WordPress (secondo passo)

### 2. Prosegui con WordPress

Dopo MariaDB, crea il container **WordPress**, che necessita del database per funzionare.

#### Dockerfile di WordPress

Il [requirements/wordpress/Dockerfile](srcs/requirements/wordpress/Dockerfile) costruisce l'immagine:

* Installa PHP-FPM e le estensioni necessarie.
* Installa WP-CLI per la gestione di WordPress da linea di comando
* Scarica e prepara i file di WordPress
* Copia il file di configurazione PHP-FPM (`www.conf`)
* Copia lo script di inizializzazione (`init-wordpress.sh`)
* Imposta il comando di avvio

#### File di configurazione (`www.conf`)

Il file [requirements/wordpress/conf/www.conf](srcs/requirements/wordpress/conf/www.conf) configura il pool (gruppo di processi) di PHP-FPM, impostando parametri come utente, socket, limiti di processo e altro.

#### Script di inizializzazione (`init-wordpress.sh`)

Lo script [requirements/wordpress/tools/init-wordpress.sh](srcs/requirements/wordpress/tools/init-wordpress.sh) viene eseguito come processo principale (PID 1) del container:

* Genera il file `wp-config.php` con le variabili d’ambiente
* Installa WordPress e crea gli utenti richiesti tramite WP-CLI
* Avvia PHP-FPM con `exec php-fpm-version -F` (così PHP-FPM diventa PID 1)

### Test WordPress

Ora avvia entrambi i container e verifica l'interazione:

```bash
# Crea la rete Docker
docker network create wordpress_network 2>/dev/null || true

# Build e avvia MariaDB
docker build -f srcs/requirements/mariadb/Dockerfile -t mariadb srcs/requirements/mariadb && docker run -d --name mariadb --network wordpress_network -v mariadb_data:/var/lib/mysql mariadb

# Attendi qualche secondo che MariaDB sia pronto, servirebbe un healthcheck che metteremo nel docker-compose.yml
sleep 10

# Build e avvia WordPress
docker build -f srcs/requirements/wordpress/Dockerfile -t wordpress srcs/requirements/wordpress && docker run -d --name wordpress --network wordpress_network -v wordpress_data:/var/www/html wordpress
```

**Test PHP-FPM**

```bash
# Verifica che PHP-FPM sia in esecuzione (PID 1)
docker exec -it wordpress ps aux | grep php-fpm

# Verifica connessione al database
docker exec -it wordpress php -r "
\$m = new mysqli('mariadb', 'liv', 'inception1', 'database_mysql');
echo \$m->connect_error ? 'ERRORE: '.\$m->connect_error : 'OK';
"

# Verifica che wp-config.php sia stato generato
docker exec -it wordpress cat /var/www/html/wp-config.php | head -20

# Verifica WP-CLI installato e funzionante
docker exec -it wordpress wp --info --allow-root

# Verifica che WordPress sia installato (se installato, stampa 'WordPress installato', altrimenti errore)
docker exec -it wordpress wp core is-installed --allow-root --path=/var/www/html && echo "WordPress installato" || echo "WordPress NON installato"

# Verifica gli utenti WordPress creati
docker exec -it wordpress wp user list --allow-root
```

**Cosa verificare:**

* [ ] PHP-FPM in esecuzione (PID 1) - verificato con `ps aux | grep php-fpm`
* [ ] Connessione al database funziona - risultato: `OK` dal comando mysqli
* [ ] wp-config.php generato - visibile con `cat /var/www/html/wp-config.php`
* [ ] WordPress installato correttamente - stampa "WordPress installato"
* [ ] Due utenti WP creati (admin + normale) - visibili con `wp user list`

---

## Sviluppo Step-by-Step: NGINX (terzo passo)

### 3. Infine NGINX

L’ultimo container da creare è **NGINX**, che funge da reverse proxy verso PHP-FPM (WordPress).

Un **reverse proxy** è un server che riceve le richieste HTTP/HTTPS dai client (browser) e le inoltra al servizio backend appropriato, in questo caso PHP-FPM che gestisce WordPress. NGINX si occupa di terminare la connessione SSL, gestire la sicurezza, e smistare il traffico verso WordPress.

#### Dockerfile di NGINX

Il [requirements/nginx/Dockerfile](srcs/requirements/nginx/Dockerfile) costruisce l'immagine:

* Installa NGINX
* Copia il file di configurazione personalizzato (`nginx.conf`)
* Genera i certificati SSL self-signed
* Espone la porta 443
* Imposta il comando di avvio (`CMD ["nginx", "-g", "daemon off;"]`)

#### File di configurazione (`nginx.conf`)

Il file [requirements/nginx/conf/nginx.conf](srcs/requirements/nginx/conf/nginx.conf) definisce:

* Il server HTTPS (porta 443)
* Il percorso dei certificati SSL
* Il proxy verso il backend PHP-FPM (WordPress)
* Le regole di sicurezza e i parametri di base

NGINX non necessita di uno script di avvio: il processo principale è avviato direttamente dal Dockerfile tramite `CMD`.

### Test NGINX

> **Prerequisiti:** Prima di testare, assicurati di aver configurato il dominio in `/etc/hosts` (vedi [prerequisiti](#prerequisiti)) - senza questo i comandi non funzioneranno.

```bash
# Crea la rete Docker
docker network create wordpress_network 2>/dev/null || true

# Build e avvia MariaDB
docker build -f srcs/requirements/mariadb/Dockerfile -t mariadb srcs/requirements/mariadb && docker run -d --name mariadb --network wordpress_network -v mariadb_data:/var/lib/mysql mariadb

# Attendi qualche secondo che MariaDB sia pronto, servirebbe un healthcheck che metteremo nel docker-compose.yml
sleep 10

# Build e avvia WordPress
docker build -f srcs/requirements/wordpress/Dockerfile -t wordpress srcs/requirements/wordpress && docker run -d --name wordpress --network wordpress_network -v wordpress_data:/var/www/html wordpress

# Build e avvia NGINX (monta il volume WordPress per servire i file)
docker build -f srcs/requirements/nginx/Dockerfile -t nginx srcs/requirements/nginx && docker run -d --name nginx --network wordpress_network -v wordpress_data:/var/www/html -p 443:443 nginx
```

**Test di connessione HTTPS:**

```bash
# Test HTTPS (la flag -k è obbligatoria perché il certificato SSL è self-signed, quindi non riconosciuto come valido. Senza -k, curl rifiuterebbe la connessione per motivi di sicurezza)
curl -k https://tuo-login-intra.42.fr
```

**Test HTTP (deve fallire!):**

```bash
# Secondo il subject, il sito DEVE essere accessibile solo tramite HTTPS
# Se provi con HTTP, la connessione deve fallire o restituire errore
# (es: connection refused, 444, 400, 301, 308)
curl -vk http://tuo-login-intra.42.fr
# Se ricevi una risposta o la pagina si apre in HTTP, la configurazione NON è corretta.
```

**Verifica certificato SSL:**

```bash
# Controlla i dettagli del certificato SSL
openssl s_client -connect tuo-login-intra.42.fr:443 -servername tuo-login-intra.42.fr
```

**Cosa verificare:**

* [ ] Porta 443 accessibile
* [ ] Certificato SSL valido (self-signed)
* [ ] Pagina WordPress caricata
* [ ] Login admin funziona: `https://tuo-login-intra.42.fr/wp-admin`

---

## Sviluppo Step-by-Step: docker-compose.yml (quarto passo)

In questo step crei il file `srcs/docker-compose.yml` per orchestrare i 3 servizi (MariaDB, WordPress, NGINX), la rete e i volumi.

> Promemoria: metti le variabili segrete nel file `srcs/.env` e poi passale ai container tramite `environment:` in `docker-compose.yml`

**Cosa deve includere (minimo):**

* 3 servizi: `mariadb`, `wordpress`, `nginx`
* Una rete condivisa (es. `wordpress_network`)
* Volumi persistenti per MariaDB e WordPress bind mount (mappatura diretta: cartella PC ↔ cartella Container) in `/home/${NOME_INTRA}/data/...`
* Porta: Solo `nginx` espone la porta 443 (`ports - "443:443"`) verso l'host. MariaDB e WordPress NON devono avere la sezione `ports` (sono chiusi all'esterno e usano solo nella rete interna).
* Variabili d'ambiente lette da `srcs/.env`
* `depends_on`/healthcheck per avviare WordPress solo quando MariaDB è pronta

---

## Sviluppo Step-by-Step: Makefile (quinto passo)

In questo step aggiungi un `Makefile` per automatizzare i comandi piu usati (build/up/down/destroy) e preparare le directory dei volumi.

Nota Importante: Poiché usi volumi su path specifici (bind mounts), il makefile deve includere @mkdir -p per creare le cartelle dati prima dei container.

**Esempio di target utili:**

* `make build` → `@mkdir -p "/home/$(NOME_INTRA)/data/..."` + `docker compose up -d --build`
* `make up` / `make down`
* `make destroy` → opzionale per pulizia completa (container/immagini/rete/volumi e directory dati)

---

## Comandi Utili per Debug

### Logs
```bash
# Log di tutti i container
docker compose -f srcs/docker-compose.yml logs -f

# Log di un singolo container
docker logs -f mariadb
docker logs -f wordpress
docker logs -f nginx
```

### Shell nei container
```bash
docker exec -it mariadb bash
docker exec -it wordpress bash
docker exec -it nginx bash
```

### Stato e info
```bash
# Stato containers
docker ps -a

# Stato con healthcheck
docker ps --format "table {{.Names}}\t{{.Status}}"

# Ispeziona container
docker inspect mariadb

# Verifica network
docker network inspect wordpress_network
```

### Ricostruzione
```bash
# Ricostruisci un singolo container
docker compose -f srcs/docker-compose.yml build mariadb
docker compose -f srcs/docker-compose.yml up -d mariadb

# Ricostruisci tutto senza cache
docker compose -f srcs/docker-compose.yml build --no-cache
```

### Pulizia COMPLETA

> **ATTENZIONE:** Questi comandi eliminano TUTTO. Usali spesso durante lo sviluppo per ripartire da zero, tra un test e l'altro. Se qualcosa non funziona, è probabile che un residuo di dati o configurazioni precedenti stia interferendo, prima di cambiare codice, fai pulizia completa!

```bash
# 1. Ferma tutti i container del progetto
docker stop mariadb wordpress nginx 2>/dev/null

# 2. Rimuovi i container
docker rm mariadb wordpress nginx 2>/dev/null

# 3. Rimuovi le immagini custom
docker rmi mariadb wordpress nginx 2>/dev/null

# 4. Rimuovi i volumi Docker
docker volume rm mariadb_data wordpress_data srcs_mariadb_data srcs_wordpress_data 2>/dev/null

# 5. Rimuovi la rete
docker network rm wordpress_network 2>/dev/null

# 6. Rimuovi i dati persistenti sul filesystem
sudo rm -rf ~/data/mariadb ~/data/wordpress

# 7. (Opzionale) Pulizia generale Docker - rimuove TUTTO ciò che non è in uso
docker system prune -a --volumes
```

**One-liner per pulizia veloce:**
```bash
docker stop mariadb wordpress nginx 2>/dev/null; docker rm mariadb wordpress nginx 2>/dev/null; docker rmi mariadb wordpress nginx 2>/dev/null; docker volume rm mariadb_data wordpress_data srcs_mariadb_data srcs_wordpress_data 2>/dev/null; docker network rm wordpress_network 2>/dev/null; sudo rm -rf ~/data/mariadb ~/data/wordpress
```

---

## Volumi Persistenti

I dati sono salvati in:
- `/home/tuo-login-intra/data/mariadb` → Database MySQL
- `/home/tuo-login-intra/data/wordpress` → File WordPress

---

## Rete Docker

Tutti i container sono sulla stessa rete bridge:
- **Nome:** `wordpress_network`
- **Driver:** bridge

I container comunicano usando i nomi dei servizi:
- `mariadb` → hostname del database
- `wordpress` → hostname per PHP-FPM

- `nginx` → non chiamato da altri, espone porta 443