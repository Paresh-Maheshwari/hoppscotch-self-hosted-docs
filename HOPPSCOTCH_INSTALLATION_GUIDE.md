# Hoppscotch Self-Hosted Installation Guide

This guide provides complete instructions for setting up Hoppscotch Community Edition in a self-hosted environment using Docker Compose.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Environment Configuration](#environment-configuration)
3. [Basic Installation (Individual Containers)](#basic-installation-individual-containers)
4. [Installation with Email Support](#installation-with-email-support)
5. [AIO Container Setup](#aio-container-setup)
6. [Desktop App Support](#desktop-app-support)
7. [Running Migrations](#running-migrations)
8. [Troubleshooting](#troubleshooting)
9. [Maintenance](#maintenance)

---

## Prerequisites

- Docker and Docker Compose installed
- PostgreSQL database (can be containerized)
- Minimum 2GB RAM
- Ports 3000, 3100, 3170, 5432 available
- For email support: Additional ports 1025, 8025
- For desktop app: Port 3200 exposed

---

## Environment Configuration

Before installation, create a `.env` file with the following variables:

> **Important**: Ensure environment values are **not enclosed within quotes** [""]

### Complete .env Template

```env
#-----------------------Backend Config------------------------------#

# Prisma Config
DATABASE_URL=postgresql://hoppscotch:hoppscotchpassword@postgres:5432/hoppscotchdb

# (Optional) AIO container alternate port (default: 80)
HOPP_AIO_ALTERNATE_PORT=80

# Sensitive Data Encryption Key (32 characters) - CHANGE IN PRODUCTION
DATA_ENCRYPTION_KEY=ReplaceWith32CharacterSecret1234

# Whitelisted origins for cross-origin communication
# - localhost ports: app, backend, development servers
# - app://localhost_3200: Bundle server origin for desktop app
# - app://hoppscotch: Desktop app protocol
WHITELISTED_ORIGINS=http://localhost:3170,http://localhost:3000,http://localhost:3100,app://localhost_3200,app://hoppscotch

# SMTP Configuration (Optional - for email features)
MAILER_SMTP_URL=smtp://mailhog:1025
MAILER_ADDRESS_FROM=noreply@hoppscotch.local

#-----------------------Frontend Config------------------------------#

# Base URLs
VITE_BASE_URL=http://localhost:3000
VITE_SHORTCODE_BASE_URL=http://localhost:3000
VITE_ADMIN_URL=http://localhost:3100

# Backend URLs
VITE_BACKEND_GQL_URL=http://localhost:3170/graphql
VITE_BACKEND_WS_URL=ws://localhost:3170/graphql
VITE_BACKEND_API_URL=http://localhost:3170/v1

# Terms Of Service And Privacy Policy Links (Optional)
VITE_APP_TOS_LINK=https://docs.hoppscotch.io/support/terms
VITE_APP_PRIVACY_POLICY_LINK=https://docs.hoppscotch.io/support/privacy

# Desktop App Support - Set to true for desktop app compatibility
ENABLE_SUBPATH_BASED_ACCESS=true
```

### Key Environment Variables Explained

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@host:port/db` |
| `HOPP_AIO_ALTERNATE_PORT` | Alternate port for AIO container (optional) | `80` |
| `DATA_ENCRYPTION_KEY` | 32-character encryption key | `ReplaceWith32CharacterSecret1234` |
| `WHITELISTED_ORIGINS` | CORS allowed origins | Comma-separated URLs |
| `VITE_BASE_URL` | Frontend base URL | `http://localhost:3000` |
| `VITE_ADMIN_URL` | Admin panel URL | `http://localhost:3100` |
| `VITE_BACKEND_GQL_URL` | GraphQL endpoint | `http://localhost:3170/graphql` |
| `VITE_BACKEND_WS_URL` | WebSocket endpoint | `ws://localhost:3170/graphql` |
| `VITE_BACKEND_API_URL` | REST API endpoint | `http://localhost:3170/v1` |
| `ENABLE_SUBPATH_BASED_ACCESS` | Enable desktop app support | `true` |

---

## Basic Installation (Individual Containers)

### 1. Create docker-compose.yml

```yaml
version: "3.8"

services:
  postgres:
    image: postgres:15-alpine
    container_name: hoppscotch-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: hoppscotch
      POSTGRES_PASSWORD: hoppscotchpassword
      POSTGRES_DB: hoppscotchdb
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  frontend:
    image: hoppscotch/hoppscotch-frontend
    container_name: hoppscotch-frontend
    env_file:
      - .env
    ports:
      - "3000:3000"
      - "3200:3200"   # Required for desktop app support
    restart: unless-stopped
    depends_on:
      - backend

  backend:
    image: hoppscotch/hoppscotch-backend
    container_name: hoppscotch-backend
    env_file:
      - .env
    ports:
      - "3170:3170"
    restart: unless-stopped
    depends_on:
      - postgres

  admin:
    image: hoppscotch/hoppscotch-admin
    container_name: hoppscotch-admin
    env_file:
      - .env
    ports:
      - "3100:3100"
    restart: unless-stopped
    depends_on:
      - backend

volumes:
  pgdata:
```

### 2. Start Services

```bash
# Pull the latest images
docker pull hoppscotch/hoppscotch-frontend
docker pull hoppscotch/hoppscotch-backend
docker pull hoppscotch/hoppscotch-admin

# Start all services
docker compose up -d

# Wait for PostgreSQL to initialize
sleep 30
```

### 3. Run Database Migrations

```bash
# Method 1: Using docker compose
docker compose run --rm backend pnpm dlx prisma migrate deploy

# Method 2: Using container ID
docker ps  # Copy backend container ID
docker exec -it <backend_container_id> /bin/sh
pnpm dlx prisma migrate deploy
exit
```

---

## Installation with Email Support

### Enhanced docker-compose.yml with MailHog

```yaml
version: "3.8"

services:
  postgres:
    image: postgres:15-alpine
    container_name: hoppscotch-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: hoppscotch
      POSTGRES_PASSWORD: hoppscotchpassword
      POSTGRES_DB: hoppscotchdb
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  mailhog:
    image: mailhog/mailhog
    container_name: hoppscotch-mailhog
    restart: unless-stopped
    ports:
      - "1025:1025"  # SMTP port
      - "8025:8025"  # Web UI port

  frontend:
    image: hoppscotch/hoppscotch-frontend
    container_name: hoppscotch-frontend
    env_file:
      - .env
    ports:
      - "3000:3000"
      - "3200:3200"   # Desktop app support
    restart: unless-stopped
    depends_on:
      - backend

  backend:
    image: hoppscotch/hoppscotch-backend
    container_name: hoppscotch-backend
    env_file:
      - .env
    ports:
      - "3170:3170"
    restart: unless-stopped
    depends_on:
      - postgres
      - mailhog

  admin:
    image: hoppscotch/hoppscotch-admin
    container_name: hoppscotch-admin
    env_file:
      - .env
    ports:
      - "3100:3100"
    restart: unless-stopped
    depends_on:
      - backend

volumes:
  pgdata:
```

---

## AIO Container Setup

### Single Container Deployment

```bash
# Pull AIO container
docker pull hoppscotch/hoppscotch

# Run AIO container
docker run -p 3000:3000 -p 3100:3100 -p 3170:3170 \
  --env-file .env \
  --restart unless-stopped \
  hoppscotch/hoppscotch
```

### AIO with Docker Compose

```yaml
version: "3.8"

services:
  postgres:
    image: postgres:15-alpine
    container_name: hoppscotch-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: hoppscotch
      POSTGRES_PASSWORD: hoppscotchpassword
      POSTGRES_DB: hoppscotchdb
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  hoppscotch-aio:
    image: hoppscotch/hoppscotch
    container_name: hoppscotch-aio
    env_file:
      - .env
    ports:
      - "3000:3000"
      - "3100:3100"
      - "3170:3170"
    restart: unless-stopped
    depends_on:
      - postgres

volumes:
  pgdata:
```

---

## Desktop App Support

### Requirements for Desktop App

1. **Enable Subpath Access**: Set `ENABLE_SUBPATH_BASED_ACCESS=true`
2. **Expose Port 3200**: For bundle server communication
3. **Whitelist Origins**: Include `app://localhost_3200` and `app://hoppscotch`

### Individual Containers Setup

```bash
# Frontend with desktop app support
docker run -p 3000:3000 -p 3200:3200 \
  --env-file .env \
  --restart unless-stopped \
  hoppscotch/hoppscotch-frontend
```

### AIO Container with Subpath Access

When `ENABLE_SUBPATH_BASED_ACCESS=true`, AIO container provides:

| Service | Route | URL |
|---------|-------|-----|
| Hoppscotch App | `/` | http://localhost:3000/ |
| Admin Dashboard | `/admin` | http://localhost:3000/admin |
| Backend API | `/backend` | http://localhost:3000/backend |

### Port Conflicts with AIO

If port 80 conflicts (Rootless Docker, Podman, OpenShift):

```env
HOPP_AIO_ALTERNATE_PORT=8080
```

---

## Running Migrations

### Method 1: Docker Compose (Recommended)

```bash
# For individual containers
docker compose run --rm backend pnpm dlx prisma migrate deploy

# For AIO container
docker compose run --rm hoppscotch-aio pnpm dlx prisma migrate deploy
```

### Method 2: Interactive Shell

```bash
# Get container ID
docker ps

# Open shell in backend container
docker exec -it <backend_container_id> /bin/sh

# Run migration
pnpm dlx prisma migrate deploy

# Exit shell
exit
```

### Method 3: One-time Container

```bash
# For backend container
docker run -it --entrypoint sh --env-file .env hoppscotch/hoppscotch-backend
pnpm dlx prisma migrate deploy

# For AIO container
docker run -it --entrypoint sh --env-file .env hoppscotch/hoppscotch
pnpm dlx prisma migrate deploy
```

### Migration Error Handling

If you encounter:
```
Database migration not found. Please check the documentation...
```

This means the backend started before migrations ran. Use Method 3 above to run migrations first.

---

## Troubleshooting

### Common Issues

#### 1. Port Already in Use
```bash
# Check what's using the port
netstat -tulpn | grep :3170

# Stop conflicting containers
docker stop $(docker ps -q --filter "publish=3170")
```

#### 2. Database Migration Errors
```bash
# Hard reset database configuration
docker exec -it hoppscotch-postgres psql -U hoppscotch -d hoppscotchdb -c "TRUNCATE \"InfraConfig\";"

# Restart backend
docker compose restart backend
```

#### 3. Desktop App Connection Issues
- Ensure `ENABLE_SUBPATH_BASED_ACCESS=true`
- Verify port 3200 is exposed and accessible
- Check `WHITELISTED_ORIGINS` includes desktop app origins

#### 4. Email Not Working
```bash
# Check backend logs
docker logs hoppscotch-backend --tail 20

# Test SMTP connection
python3 -c "
import smtplib
server = smtplib.SMTP('localhost', 1025)
print('✅ SMTP connection successful')
server.quit()
"
```

#### 5. Environment Variables Not Loading
- Ensure `.env` file is in the correct directory
- Verify no quotes around values
- Check file permissions: `chmod 644 .env`

### Complete Reset
```bash
# WARNING: Deletes all data
docker compose down
docker volume rm $(docker volume ls -q | grep pgdata)
docker compose up -d
sleep 30
docker compose run --rm backend pnpm dlx prisma migrate deploy
```

---

## Maintenance

### Regular Tasks

#### Update Images
```bash
docker compose pull
docker compose up -d
```

#### Backup Database
```bash
docker exec hoppscotch-postgres pg_dump -U hoppscotch hoppscotchdb > backup.sql
```

#### Restore Database
```bash
docker exec -i hoppscotch-postgres psql -U hoppscotch hoppscotchdb < backup.sql
```

#### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker logs hoppscotch-backend -f --tail 50
```

#### Health Check
```bash
# Service status
docker compose ps

# Resource usage
docker stats

# Test endpoints
curl http://localhost:3170/health
curl http://localhost:3000
curl http://localhost:3100
```

---

## Security Considerations

1. **Change Default Credentials**: Update PostgreSQL and encryption keys
2. **Use Strong Encryption Key**: Generate secure 32-character `DATA_ENCRYPTION_KEY`
3. **Configure HTTPS**: Use reverse proxy (nginx/traefik) for SSL
4. **Network Security**: Use Docker networks, limit exposed ports
5. **Regular Updates**: Keep Docker images updated
6. **Backup Strategy**: Automated database backups
7. **Environment Variables**: Never commit `.env` files to version control

### Production .env Example

```env
DATABASE_URL=postgresql://prod_user:secure_password@db.example.com:5432/hoppscotch_prod
DATA_ENCRYPTION_KEY=your-super-secure-32-char-key-here
VITE_BASE_URL=https://hoppscotch.yourdomain.com
VITE_ADMIN_URL=https://hoppscotch.yourdomain.com/admin
VITE_BACKEND_GQL_URL=https://hoppscotch.yourdomain.com/graphql
VITE_BACKEND_WS_URL=wss://hoppscotch.yourdomain.com/graphql
VITE_BACKEND_API_URL=https://hoppscotch.yourdomain.com/v1
WHITELISTED_ORIGINS=https://hoppscotch.yourdomain.com,app://localhost_3200,app://hoppscotch
ENABLE_SUBPATH_BASED_ACCESS=true
```

---

## Access URLs

### Individual Containers
- **Frontend**: http://localhost:3000
- **Admin Panel**: http://localhost:3100
- **Backend API**: http://localhost:3170
- **Desktop Bundle**: http://localhost:3200
- **MailHog UI**: http://localhost:8025 (if enabled)

### AIO Container (Subpath Access)
- **Frontend**: http://localhost:3000/
- **Admin Panel**: http://localhost:3000/admin
- **Backend API**: http://localhost:3000/backend

---

## Support

- **Official Documentation**: https://docs.hoppscotch.io/
- **GitHub Repository**: https://github.com/hoppscotch/hoppscotch
- **GitHub Issues**: https://github.com/hoppscotch/hoppscotch/issues
- **Community Discussions**: https://github.com/hoppscotch/hoppscotch/discussions

---

*Last updated: July 2025 - Based on official Hoppscotch documentation*
