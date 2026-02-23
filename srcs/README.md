*This project has been created as part of the 42 curriculum by <ldei-sva>.*

# Inception

## Description

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

## Project Architecture & Design Choices

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

## Instructions

### Requirements

* Docker
* Docker Compose

### Installation & Execution

1. Clone the repository:

   ```bash
   git clone https://github.com/<username>/inception.git
   cd inception
   ```

2. Build and start the infrastructure:

   ```bash
   docker compose up --build
   ```

3. Stop the services:

   ```bash
   docker compose down
   ```

4. Remove volumes (if needed):

   ```bash
   docker compose down -v
   ```

### Project Structure

```
.
├── Makefile
├── docker-compose.yml
├── srcs/
│   ├── requirements/
│   │   ├── nginx/
│   │   ├── mariadb/
│   │   └── wordpress/
│   └── .env
```

* `docker-compose.yml` defines services, volumes, and networks.
* `requirements/` contains Dockerfiles and service configuration.
* `.env` stores environment variables.

---

## Resources

### Official Documentation

* Docker Official Documentation
* Docker Compose Documentation
* NGINX Documentation
* MariaDB Documentation
* WordPress Documentation

### Articles & Tutorials

* Docker networking and volumes best practices
* Container security fundamentals
* Infrastructure design patterns

### AI Usage Disclosure

AI tools (such as ChatGPT) were used during this project for:

* Understanding Docker concepts and best practices
* Clarifying differences between Docker features (volumes, networks, secrets)
* Reviewing configuration structure and documentation writing
* Improving README clarity and structure

AI was **not** used to automatically generate full project configurations without understanding. All configurations and implementation decisions were reviewed, tested, and validated manually.

---

## Additional Notes

This project emphasizes:

* Clean infrastructure design
* Service isolation
* Secure configuration management
* Reproducibility and portability

The objective is not only to make services run, but to understand *how* and *why* containerized infrastructures work.
