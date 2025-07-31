# Hoppscotch EC2 Deployment Guide

This guide covers deploying Hoppscotch on AWS EC2 instances with public IP access.

## Table of Contents
1. [EC2 Instance Setup](#ec2-instance-setup)
2. [Security Group Configuration](#security-group-configuration)
3. [Environment Configuration for Public IP](#environment-configuration-for-public-ip)
4. [Docker Compose Setup](#docker-compose-setup)
5. [SSL/HTTPS Configuration](#sslhttps-configuration)
6. [Domain Setup (Optional)](#domain-setup-optional)
7. [Troubleshooting](#troubleshooting)

---

## EC2 Instance Setup

### Minimum Requirements
- **Instance Type**: t3.medium or larger (2 vCPU, 4GB RAM)
- **Storage**: 20GB+ EBS volume
- **OS**: Ubuntu 22.04 LTS or Amazon Linux 2023
- **Public IP**: Elastic IP recommended for production

### Initial Setup Commands

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout and login again for docker group to take effect
exit
```

---

## Security Group Configuration

### Required Inbound Rules

| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|--------|-------------|
| HTTP | TCP | 80 | 0.0.0.0/0 | Web access |
| HTTPS | TCP | 443 | 0.0.0.0/0 | Secure web access |
| Custom TCP | TCP | 3000 | 0.0.0.0/0 | Hoppscotch Frontend |
| Custom TCP | TCP | 3100 | 0.0.0.0/0 | Admin Panel |
| Custom TCP | TCP | 3170 | 0.0.0.0/0 | Backend API |
| Custom TCP | TCP | 3200 | 0.0.0.0/0 | Desktop App Support |
| SSH | TCP | 22 | Your IP | SSH access |

### AWS CLI Security Group Setup

```bash
# Create security group
aws ec2 create-security-group \
    --group-name hoppscotch-sg \
    --description "Security group for Hoppscotch"

# Add inbound rules
aws ec2 authorize-security-group-ingress \
    --group-name hoppscotch-sg \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-name hoppscotch-sg \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-name hoppscotch-sg \
    --protocol tcp \
    --port 3000 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-name hoppscotch-sg \
    --protocol tcp \
    --port 3100 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-name hoppscotch-sg \
    --protocol tcp \
    --port 3170 \
    --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
    --group-name hoppscotch-sg \
    --protocol tcp \
    --port 3200 \
    --cidr 0.0.0.0/0
```

---

## Environment Configuration for Public IP

### Get Your EC2 Public IP

```bash
# Get public IP from instance metadata
curl -s http://169.254.169.254/latest/meta-data/public-ipv4

# Or check in AWS console
aws ec2 describe-instances --query 'Reservations[*].Instances[*].PublicIpAddress'
```

### .env Configuration Template

Replace `YOUR_EC2_PUBLIC_IP` with your actual EC2 public IP address:

```env
#-----------------------Backend Config------------------------------#

# Prisma Config
DATABASE_URL=postgresql://hoppscotch:hoppscotchpassword@postgres:5432/hoppscotchdb

# Sensitive Data Encryption Key (32 characters) - CHANGE IN PRODUCTION
DATA_ENCRYPTION_KEY=your-super-secure-32-char-key-here

# Whitelisted origins for cross-origin communication
WHITELISTED_ORIGINS=http://YOUR_EC2_PUBLIC_IP:3170,http://YOUR_EC2_PUBLIC_IP:3000,http://YOUR_EC2_PUBLIC_IP:3100,http://YOUR_EC2_PUBLIC_IP,https://YOUR_EC2_PUBLIC_IP,app://localhost_3200,app://hoppscotch

# SMTP Configuration (Optional - for email features)
MAILER_SMTP_URL=smtp://mailhog:1025
MAILER_ADDRESS_FROM=noreply@hoppscotch.local

#-----------------------Frontend Config------------------------------#

# Base URLs - Replace YOUR_EC2_PUBLIC_IP with actual IP
VITE_BASE_URL=http://YOUR_EC2_PUBLIC_IP:3000
VITE_SHORTCODE_BASE_URL=http://YOUR_EC2_PUBLIC_IP:3000
VITE_ADMIN_URL=http://YOUR_EC2_PUBLIC_IP:3100

# Backend URLs
VITE_BACKEND_GQL_URL=http://YOUR_EC2_PUBLIC_IP:3170/graphql
VITE_BACKEND_WS_URL=ws://YOUR_EC2_PUBLIC_IP:3170/graphql
VITE_BACKEND_API_URL=http://YOUR_EC2_PUBLIC_IP:3170/v1

# Terms Of Service And Privacy Policy Links (Optional)
VITE_APP_TOS_LINK=https://docs.hoppscotch.io/support/terms
VITE_APP_PRIVACY_POLICY_LINK=https://docs.hoppscotch.io/support/privacy

# Desktop App Support
ENABLE_SUBPATH_BASED_ACCESS=true
```

### Example with Real IP (e.g., 54.123.45.67)

```env
#-----------------------Backend Config------------------------------#
DATABASE_URL=postgresql://hoppscotch:hoppscotchpassword@postgres:5432/hoppscotchdb
DATA_ENCRYPTION_KEY=your-super-secure-32-char-key-here
WHITELISTED_ORIGINS=http://54.123.45.67:3170,http://54.123.45.67:3000,http://54.123.45.67:3100,http://54.123.45.67,https://54.123.45.67,app://localhost_3200,app://hoppscotch
MAILER_SMTP_URL=smtp://mailhog:1025
MAILER_ADDRESS_FROM=noreply@hoppscotch.local

#-----------------------Frontend Config------------------------------#
VITE_BASE_URL=http://54.123.45.67:3000
VITE_SHORTCODE_BASE_URL=http://54.123.45.67:3000
VITE_ADMIN_URL=http://54.123.45.67:3100
VITE_BACKEND_GQL_URL=http://54.123.45.67:3170/graphql
VITE_BACKEND_WS_URL=ws://54.123.45.67:3170/graphql
VITE_BACKEND_API_URL=http://54.123.45.67:3170/v1
VITE_APP_TOS_LINK=https://docs.hoppscotch.io/support/terms
VITE_APP_PRIVACY_POLICY_LINK=https://docs.hoppscotch.io/support/privacy
ENABLE_SUBPATH_BASED_ACCESS=true
```

---

## Docker Compose Setup

### Standard Setup (Individual Containers)

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
      - "1025:1025"
      - "8025:8025"

  frontend:
    image: hoppscotch/hoppscotch-frontend
    container_name: hoppscotch-frontend
    env_file:
      - .env
    ports:
      - "80:3000"     # Map port 80 for easy access
      - "3000:3000"   # Standard port
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

### Deployment Commands

```bash
# Clone or create your setup
mkdir hoppscotch-ec2
cd hoppscotch-ec2

# Create your .env file with EC2 public IP
nano .env

# Create docker-compose.yml
nano docker-compose.yml

# Start services
docker-compose up -d

# Wait for services to start
sleep 30

# Run database migrations
docker-compose run --rm backend pnpm dlx prisma migrate deploy

# Check status
docker-compose ps
```

---

## SSL/HTTPS Configuration

### Option 1: Using Nginx Reverse Proxy

#### Install Nginx and Certbot

```bash
sudo apt install nginx certbot python3-certbot-nginx -y
```

#### Nginx Configuration

Create `/etc/nginx/sites-available/hoppscotch`:

```nginx
server {
    listen 80;
    server_name YOUR_DOMAIN_OR_IP;

    # Frontend
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Admin Panel
    location /admin {
        proxy_pass http://localhost:3100;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Backend API
    location /api {
        proxy_pass http://localhost:3170;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # GraphQL
    location /graphql {
        proxy_pass http://localhost:3170/graphql;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

#### Enable and Start Nginx

```bash
sudo ln -s /etc/nginx/sites-available/hoppscotch /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

#### Get SSL Certificate (if using domain)

```bash
sudo certbot --nginx -d yourdomain.com
```

### Option 2: Using Traefik (Docker-based)

Add to your docker-compose.yml:

```yaml
  traefik:
    image: traefik:v2.10
    container_name: traefik
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    restart: unless-stopped
```

---

## Domain Setup (Optional)

### Using Route 53

1. **Create Hosted Zone** for your domain
2. **Create A Record** pointing to your EC2 public IP
3. **Update .env file** with your domain:

```env
VITE_BASE_URL=https://yourdomain.com
VITE_ADMIN_URL=https://yourdomain.com/admin
VITE_BACKEND_GQL_URL=https://yourdomain.com/graphql
VITE_BACKEND_WS_URL=wss://yourdomain.com/graphql
VITE_BACKEND_API_URL=https://yourdomain.com/v1
WHITELISTED_ORIGINS=https://yourdomain.com,app://localhost_3200,app://hoppscotch
```

### Using Elastic IP

```bash
# Allocate Elastic IP
aws ec2 allocate-address --domain vpc

# Associate with instance
aws ec2 associate-address --instance-id i-1234567890abcdef0 --allocation-id eipalloc-12345678
```

---

## Troubleshooting

### Common EC2 Issues

#### 1. Connection Refused
```bash
# Check if services are running
docker-compose ps

# Check security group rules
aws ec2 describe-security-groups --group-names hoppscotch-sg

# Test local connectivity
curl -I http://localhost:3000
```

#### 2. Public IP Access Issues
```bash
# Verify public IP
curl -s http://169.254.169.254/latest/meta-data/public-ipv4

# Test from outside
curl -I http://YOUR_EC2_PUBLIC_IP:3000

# Check firewall
sudo ufw status
```

#### 3. Database Connection Issues
```bash
# Check PostgreSQL logs
docker logs hoppscotch-postgres

# Verify database connectivity
docker exec -it hoppscotch-postgres psql -U hoppscotch -d hoppscotchdb -c "SELECT 1;"
```

#### 4. CORS Issues
- Ensure your EC2 public IP is in `WHITELISTED_ORIGINS`
- Include both HTTP and HTTPS versions
- Add port numbers if using non-standard ports

### Performance Optimization

#### 1. Instance Sizing
- **Development**: t3.medium (2 vCPU, 4GB RAM)
- **Production**: t3.large or larger (2+ vCPU, 8GB+ RAM)

#### 2. Storage Optimization
```bash
# Use GP3 volumes for better performance
aws ec2 modify-volume --volume-id vol-1234567890abcdef0 --volume-type gp3
```

#### 3. Monitoring
```bash
# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U ./amazon-cloudwatch-agent.rpm
```

---

## Production Checklist

### Security
- [ ] Change default passwords and encryption keys
- [ ] Use Elastic IP for static public IP
- [ ] Configure SSL/TLS certificates
- [ ] Restrict security group rules to necessary IPs
- [ ] Enable CloudTrail logging
- [ ] Set up VPC with private subnets for database

### Backup
- [ ] Enable EBS snapshots
- [ ] Set up database backups
- [ ] Configure S3 backup storage

### Monitoring
- [ ] Set up CloudWatch alarms
- [ ] Configure log aggregation
- [ ] Monitor resource usage

### High Availability
- [ ] Use Application Load Balancer
- [ ] Deploy across multiple AZs
- [ ] Use RDS for managed database
- [ ] Implement auto-scaling

---

## Access URLs

After deployment, your Hoppscotch instance will be available at:

- **Frontend**: `http://YOUR_EC2_PUBLIC_IP:3000` or `http://YOUR_EC2_PUBLIC_IP`
- **Admin Panel**: `http://YOUR_EC2_PUBLIC_IP:3100`
- **Backend API**: `http://YOUR_EC2_PUBLIC_IP:3170`
- **MailHog UI**: `http://YOUR_EC2_PUBLIC_IP:8025`

---

*For additional support, refer to the main [HOPPSCOTCH_INSTALLATION_GUIDE.md](./HOPPSCOTCH_INSTALLATION_GUIDE.md)*
