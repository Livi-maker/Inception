*This project has been created as part of the 42 curriculum by **ldei-sva**.*

<div align="center">

# Inception

[![42 School](https://img.shields.io/badge/42-School-000000?style=flat&logo=42&logoColor=white)](https://42.fr)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=flat&logo=mariadb&logoColor=white)](https://mariadb.org/)
[![WordPress](https://img.shields.io/badge/WordPress-21759B?style=flat&logo=wordpress&logoColor=white)](https://wordpress.org/)
[![NGINX](https://img.shields.io/badge/NGINX-009639?style=flat&logo=nginx&logoColor=white)](https://nginx.org/)

*A Docker-based infrastructure project featuring NGINX, WordPress, and MariaDB*

</div>

---

## 📖 Description

**Inception** is a system administration project from the 42 curriculum focused on containerization, service orchestration, and infrastructure design.

The goal of the project is to build a small production-like infrastructure using **Docker** and **Docker Compose**, composed of multiple interconnected services (such as a web server, a database, and a CMS). Each service runs in its own container, ensuring isolation, modularity, and scalability.

Instead of relying on pre-configured images, the core services must be built and configured manually. This approach provides a deeper understanding of:

* Containerization principles
* Networking between services
* Data persistence
* Environment configuration
* Basic security practices
* Infrastructure design and orchestration

The final result is a reproducible, modular, and isolated multi-container environment simulating a real-world server setup.

---

## 🏗️ Architecture Overview

```
                    ┌─────────────────────────────────────────────────────┐
                    │                   Docker Network                     │
                    │                    (inception)                       │
                    │                                                      │
    HTTPS :443      │    ┌──────────┐      ┌───────────┐    ┌──────────┐  │
   ─────────────────┼───►│  NGINX   │─────►│ WordPress │───►│ MariaDB  │  │
                    │    │ (TLS/SSL)│ :9000│  (PHP-FPM)│:3306│   (DB)   │  │
                    │    └──────────┘      └───────────┘    └──────────┘  │
                    │          │                 │                │       │
                    └──────────┼─────────────────┼────────────────┼───────┘
                               │                 │                │
                    ┌──────────▼─────┐  ┌───────▼──────┐  ┌──────▼───────┐
                    │   Certificates │  │   WordPress  │  │    MariaDB   │
                    │     Volume     │  │    Volume    │  │    Volume    │
                    └────────────────┘  └──────────────┘  └──────────────┘
```

---

## 🎯 Project Architecture & Design Choices

### Why Docker?

Docker allows applications to run inside lightweight containers that share the host system kernel while remaining isolated from each other. Compared to traditional virtualization, Docker provides faster startup times, lower resource consumption, and easier deployment.

### Virtual Machines vs Docker

| Virtual Machines                | Docker Containers       |
| ------------------------------- | ----------------------- |
| Include a full guest OS         | Share host OS kernel    |
| Heavier resource usage          | Lightweight             |
| Slower boot time                | Near-instant startup    |
| Strong hardware-level isolation | Process-level isolation |

**Design choice:** Docker was chosen for efficiency, portability, and simplicity in managing multi-service architectures.

---

### Secrets vs Environment Variables

| Secrets                                       | Environment Variables              |
| --------------------------------------------- | ---------------------------------- |
| Stored securely (not exposed in image layers) | Visible in container configuration |
| Safer for sensitive data (passwords, keys)    | Suitable for non-sensitive config  |
| Managed separately from application logic     | Often defined in `.env` files      |

**Design choice:** Sensitive credentials (e.g., database passwords) should be managed using Docker secrets whenever possible to enhance security.

---

### Docker Network vs Host Network

| Docker Network (Bridge)         | Host Network              |
| ------------------------------- | ------------------------- |
| Isolated internal network       | Shares host network stack |
| Better service separation       | No isolation              |
| Explicit port exposure required | Direct port access        |

**Design choice:** A bridge network is used to ensure service isolation and controlled communication between containers.

---

### Docker Volumes vs Bind Mounts

| Docker Volumes             | Bind Mounts                  |
| -------------------------- | ---------------------------- |
| Managed by Docker          | Directly linked to host path |
| Better portability         | Host-dependent               |
| Recommended for production | Common in development        |

**Design choice:** Docker volumes are used to ensure persistent and portable data storage independent of host-specific paths.

---

## 🛠️ Services Overview

| Service | Description | Port |
|---------|-------------|------|
| **NGINX** | Reverse proxy with TLS/SSL termination | 443 (HTTPS) |
| **WordPress** | CMS running with PHP-FPM | 9000 (internal) |
| **MariaDB** | Database server for WordPress | 3306 (internal) |

---

## 🚀 Instructions

### 📋 Requirements

* Docker
* Docker Compose
* Make (optional, for Makefile commands)

### ⚙️ Installation & Execution

1. Clone the repository:

   ```bash
   git clone https://github.com/Livi-maker/Inception.git
   cd Inception
   ```

2. Create your environment file:

   ```bash
   cp srcs/.env.example srcs/.env
   # Edit srcs/.env with your credentials
   ```

3. Build and start the infrastructure:

   ```bash
   make          # or: docker compose -f srcs/docker-compose.yml up --build
   ```

4. Stop the services:

   ```bash
   make down     # or: docker compose -f srcs/docker-compose.yml down
   ```

5. Remove volumes (if needed):

   ```bash
   make fclean   # or: docker compose -f srcs/docker-compose.yml down -v
   ```

### 🔧 Makefile Commands

| Command | Description |
|---------|-------------|
| `make` | Build and start all containers |
| `make down` | Stop all containers |
| `make fclean` | Stop containers and remove volumes |
| `make re` | Rebuild everything from scratch |

### 📁 Project Structure

```
.
├── Makefile                    # Main build automation
├── README.md                   # Project documentation
├── DEV_DOC.md                  # Developer documentation
├── USER_DOC.md                 # User documentation
└── srcs/
    ├── docker-compose.yml      # Service orchestration
    ├── .env                    # Environment variables
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile      # NGINX container build
        │   └── conf/
        │       └── nginx.conf  # NGINX configuration
        ├── mariadb/
        │   ├── Dockerfile      # MariaDB container build
        │   ├── Makefile
        │   └── tools/
        │       └── script.sh   # Database init script
        └── wordpress/
            ├── Dockerfile      # WordPress container build
            ├── conf/
            │   └── www.conf    # PHP-FPM pool config
            └── tools/
                └── wordpress.sh # WordPress setup script
```

* `docker-compose.yml` defines services, volumes, and networks.
* `requirements/` contains Dockerfiles and service configuration.
* `.env` stores environment variables.

---

## 📚 Resources

### Official Documentation

* [Docker Official Documentation](https://docs.docker.com/)
* [Docker Compose Documentation](https://docs.docker.com/compose/)
* [NGINX Documentation](https://nginx.org/en/docs/)
* [MariaDB Documentation](https://mariadb.com/kb/en/)
* [WordPress Documentation](https://developer.wordpress.org/)

### Articles & Tutorials

* [Docker networking best practices](https://docs.docker.com/network/)
* [Docker volumes guide](https://docs.docker.com/storage/volumes/)
* [Container security fundamentals](https://docs.docker.com/engine/security/)

### 🤖 AI Usage Disclosure

AI tools (such as ChatGPT) were used during this project for:

* Understanding Docker concepts and best practices
* Clarifying differences between Docker features (volumes, networks, secrets)
* Reviewing configuration structure and documentation writing
* Improving README clarity and structure

AI was **not** used to automatically generate full project configurations without understanding. All configurations and implementation decisions were reviewed, tested, and validated manually.

---

## 📝 Additional Notes

This project emphasizes:

* ✅ Clean infrastructure design
* ✅ Service isolation
* ✅ Secure configuration management
* ✅ Reproducibility and portability

The objective is not only to make services run, but to understand *how* and *why* containerized infrastructures work.

---

<div align="center">

**Made with ❤️ at 42**

</div>

---
