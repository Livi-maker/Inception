# USER_DOC.md

# Inception — User Documentation

This document explains how to use and manage the Inception infrastructure stack.

---

## 1. Services Provided by the Stack

This project runs multiple services using Docker containers. The typical stack includes:

* **NGINX** — Web server handling HTTPS connections
* **WordPress** — Website content management system
* **MariaDB** — Database server storing website data

### How They Work Together

1. The user connects to the website through **NGINX** (HTTPS).
2. NGINX forwards requests to **WordPress**.
3. WordPress retrieves and stores data in **MariaDB**.
4. Persistent data is stored in Docker volumes.

---

## 2. Starting and Stopping the Project

### Requirements

* Docker installed
* Docker Compose installed

### Start the Project

From the root of the repository:

```bash
docker compose up --build
```

To run in the background:

```bash
docker compose up -d --build
```

---

### Stop the Project

```bash
docker compose down
```

---

### Stop and Remove Volumes (⚠ deletes all stored data)

```bash
docker compose down -v
```

---

## 3. Accessing the Website and Administration Panel

### Access the Website

Open your browser and go to:

```
https://localhost
```

or

```
https://<your-domain-name>
```

If using a self-signed certificate, your browser may show a security warning. You can safely proceed.

---

### Access the WordPress Admin Panel

Go to:

```
https://localhost/wp-admin
```

Log in using the administrator credentials defined in your environment configuration.

---

## 4. Credentials Management

Credentials are typically defined in:

```
srcs/.env
```

This file contains:

* Database name
* Database user
* Database password
* WordPress admin username
* WordPress admin password
* WordPress admin email

### Important Notes

* Do NOT share your `.env` file publicly.
* For production environments, sensitive data should be managed using Docker secrets instead of plain environment variables.
* If credentials are changed, you must rebuild the containers:

```bash
docker compose down
docker compose up --build
```

---

## 5. Checking That Services Are Running Correctly

### Check Running Containers

```bash
docker ps
```

You should see containers for:

* nginx
* wordpress
* mariadb

---

### Check Logs

To see logs for all services:

```bash
docker compose logs
```

To see logs for a specific service:

```bash
docker compose logs nginx
docker compose logs wordpress
docker compose logs mariadb
```

---

### Test Website Connectivity

* Open `https://localhost`
* Verify that the WordPress homepage loads.
* Log into `/wp-admin` to confirm database connectivity.

If the page does not load:

1. Check container status (`docker ps`)
2. Check logs
3. Ensure ports are not already in use
4. Verify `.env` configuration

---

## 6. Restarting a Specific Service

If needed:

```bash
docker compose restart nginx
docker compose restart wordpress
docker compose restart mariadb
```

---

## 7. Data Persistence

The project uses Docker volumes to ensure that:

* Database data remains saved even if containers are restarted.
* WordPress files persist across rebuilds.

To list volumes:

```bash
docker volume ls
```

---

## 8. Common Troubleshooting

### Port Already in Use

Stop any service using port 443:

```bash
sudo lsof -i :443
```

---

### Database Connection Error

* Verify database credentials in `.env`
* Ensure MariaDB container is running
* Check MariaDB logs

---

## Summary

This stack provides:

* A secure HTTPS web server
* A WordPress website
* A persistent database
* Isolated and reproducible containerized services

The infrastructure is designed to simulate a real-world production environment using Docker.

---

If needed, I can also generate:

* An `ADMIN_DOC.md` (more technical documentation)
* A shorter evaluation-ready version
* A version strictly aligned with 42 subject evaluation criteria
