# DEV_DOC.md

# Inception — Developer Documentation

This document explains how a developer can set up, build, run, and manage the Inception infrastructure from scratch.

---

## 1. Environment Setup

### Prerequisites

Before starting, ensure the following tools are installed:

* **Docker**
* **Docker Compose**
* GNU Make

Check installation:

```bash
docker --version
docker compose version
make --version
```

---

## 2. Project Structure

Typical structure:

```
.
├── Makefile
├── docker-compose.yml
├── srcs/
│   ├── .env
│   └── requirements/
│       ├── nginx/
│       ├── mariadb/
│       └── wordpress/
```

### Main Components

* `docker-compose.yml` → Defines services, networks, and volumes
* `Makefile` → Automates build/start/stop commands
* `srcs/.env` → Environment variables (credentials & configuration)
* `requirements/` → Contains Dockerfiles and configuration files

---

## 3. Configuration from Scratch

### 3.1 Clone the Repository

```bash
git clone <repository_url>
cd inception
```

---

### 3.2 Configure Environment Variables

Create or edit:

```
srcs/.env
```

Example:

```
DOMAIN_NAME=localhost

MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
MYSQL_PASSWORD=wp_password
MYSQL_ROOT_PASSWORD=root_password

WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=admin_password
WP_ADMIN_EMAIL=admin@example.com
```

⚠ Do not commit sensitive credentials in public repositories.

---

### 3.3 Secrets (If Implemented)

If Docker secrets are used instead of environment variables:

* Create secret files (e.g., inside `secrets/`)
* Reference them in `docker-compose.yml`
* Ensure correct file permissions

Secrets provide better security than plain environment variables.

---

## 4. Build and Launch the Project

### Using Makefile (Recommended)

Build and start:

```bash
make
```

or (depending on implementation):

```bash
make up
```

Stop containers:

```bash
make down
```

Full clean (remove containers, images, volumes):

```bash
make fclean
```

---

### Using Docker Compose Directly

Build and run:

```bash
docker compose up --build
```

Detached mode:

```bash
docker compose up -d --build
```

Stop:

```bash
docker compose down
```

Remove volumes:

```bash
docker compose down -v
```

---

## 5. Managing Containers and Volumes

### List Running Containers

```bash
docker ps
```

### List All Containers

```bash
docker ps -a
```

### View Logs

All services:

```bash
docker compose logs
```

Specific service:

```bash
docker compose logs nginx
docker compose logs mariadb
docker compose logs wordpress
```

---

### Restart a Service

```bash
docker compose restart nginx
```

---

### Execute Commands Inside a Container

```bash
docker exec -it <container_name> sh
```

Example:

```bash
docker exec -it mariadb sh
```

---

### Manage Volumes

List volumes:

```bash
docker volume ls
```

Inspect a volume:

```bash
docker volume inspect <volume_name>
```

Remove unused volumes:

```bash
docker volume prune
```

---

## 6. Data Storage and Persistence

### Where Data Is Stored

The project uses Docker volumes to persist data.

Typical volumes:

* `mariadb_data` → Database files
* `wordpress_data` → WordPress content

These volumes are managed by Docker and stored in:

```
/var/lib/docker/volumes/
```

(Host path may vary depending on system.)

---

### How Persistence Works

* Containers are ephemeral (can be destroyed).
* Volumes are independent from containers.
* When a container is recreated, it reattaches to the same volume.
* Data remains intact unless volumes are explicitly removed.

To remove persistent data:

```bash
docker compose down -v
```

---

## 7. Networking

Docker Compose automatically creates a custom bridge network.

* Services communicate internally using service names (e.g., `mariadb`).
* Only the web server (e.g., **NGINX**) exposes ports to the host.

Internal service communication example:

* WordPress connects to MariaDB using:

  ```
  host: mariadb
  ```

---

## 8. Development Workflow

When modifying:

* Dockerfile
* Configuration files
* Environment variables

You must rebuild:

```bash
docker compose up --build
```

If issues persist:

```bash
make fclean
make
```

---

## 9. Troubleshooting for Developers

### Containers Exit Immediately

Check logs:

```bash
docker compose logs <service>
```

Common causes:

* Wrong credentials
* Missing environment variables
* Permission issues
* Port conflicts

---

### Database Not Connecting

Verify:

* Service name in WordPress config
* Database credentials
* MariaDB container is running
* Volume permissions

---

## Summary

As a developer, you can:

* Configure the environment via `.env` or secrets
* Build and launch using `make` or Docker Compose
* Manage containers, networks, and volumes
* Inspect logs and debug services
* Understand exactly where data is stored and how it persists

This project simulates a production-like containerized infrastructure while maintaining full transparency and control over each component.
