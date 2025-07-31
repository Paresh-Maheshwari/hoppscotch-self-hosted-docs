# Hoppscotch Self-Hosted Complete File Structure

This document provides the complete file structure for all Hoppscotch deployment options.

## 📁 Complete Directory Structure

```
hoppscotch-self-hosted/
├── 📋 Documentation/
│   ├── README.md                           # Main overview and quick start
│   ├── HOPPSCOTCH_INSTALLATION_GUIDE.md   # Complete installation guide
│   ├── EC2_DEPLOYMENT_GUIDE.md             # AWS EC2 deployment guide
│   ├── ECS_DEPLOYMENT_GUIDE.md             # AWS ECS deployment guide
│   ├── RDS_CONFIGURATION_GUIDE.md          # RDS PostgreSQL configuration
│   ├── SMTP_EXAMPLES.md                    # Email configuration examples
│   └── FILE_STRUCTURE.md                   # This file
│
├── 🐳 Local Development/
│   ├── basic-setup/                        # No email support
│   │   ├── docker-compose.yml
│   │   ├── .env
│   │   └── start.sh
│   │
│   ├── email-setup/                        # With MailHog email
│   │   ├── docker-compose.yml
│   │   ├── .env
│   │   └── start.sh
│   │
│   └── aio-setup/                          # All-in-One container
│       ├── docker-compose.yml
│       ├── .env
│       └── start.sh
│
├── ☁️ AWS Deployments/
│   ├── ec2-setup.sh                        # EC2 one-click deployment
│   ├── deploy-ecs-rds.sh                   # ECS + RDS deployment
│   └── cloudformation-ecs-rds.yaml         # CloudFormation template
│
└── ⚙️ Current Working Files/
    ├── docker-compose.yml                  # Current setup
    ├── .env                                # Current environment
    ├── .env-aio                            # AIO environment
    └── docker-compose-aio.yml              # AIO compose file
```

## 📋 File Descriptions

### Documentation Files

| File | Purpose | Size |
|------|---------|------|
| `README.md` | Main overview with quick start options | ~8KB |
| `HOPPSCOTCH_INSTALLATION_GUIDE.md` | Complete installation guide with troubleshooting | ~25KB |
| `EC2_DEPLOYMENT_GUIDE.md` | AWS EC2 deployment with public IP | ~15KB |
| `ECS_DEPLOYMENT_GUIDE.md` | AWS ECS with Fargate deployment | ~20KB |
| `RDS_CONFIGURATION_GUIDE.md` | RDS PostgreSQL setup and optimization | ~18KB |
| `SMTP_EXAMPLES.md` | Email provider configurations | ~8KB |

### Setup Directories

#### `basic-setup/` - Local Development (No Email)
```
basic-setup/
├── docker-compose.yml    # PostgreSQL + Hoppscotch services
├── .env                  # Environment variables
└── start.sh             # One-click startup script
```

#### `email-setup/` - Local Development (With Email)
```
email-setup/
├── docker-compose.yml    # PostgreSQL + Hoppscotch + MailHog
├── .env                  # Environment with SMTP config
└── start.sh             # One-click startup with email
```

#### `aio-setup/` - All-in-One Container
```
aio-setup/
├── docker-compose.yml    # PostgreSQL + AIO container
├── .env                  # AIO environment config
└── start.sh             # AIO startup script
```

### AWS Deployment Files

| File | Purpose | Usage |
|------|---------|-------|
| `ec2-setup.sh` | EC2 deployment script | `./ec2-setup.sh` |
| `deploy-ecs-rds.sh` | ECS + RDS deployment | `./deploy-ecs-rds.sh` |
| `cloudformation-ecs-rds.yaml` | Infrastructure as Code | CloudFormation template |

## 🚀 Quick Start Commands

### Local Development
```bash
# Basic setup (no email)
cd basic-setup && ./start.sh

# With email support
cd email-setup && ./start.sh

# All-in-One container
cd aio-setup && ./start.sh
```

### AWS Deployments
```bash
# EC2 with public IP
./ec2-setup.sh

# Production ECS + RDS
./deploy-ecs-rds.sh
```

## 💾 How to Save This Structure

### Option 1: Download Individual Files
Create the directory structure and download each file:

```bash
# Create directory structure
mkdir -p hoppscotch-self-hosted/{basic-setup,email-setup,aio-setup}

# Download documentation
curl -O https://raw.githubusercontent.com/your-repo/README.md
curl -O https://raw.githubusercontent.com/your-repo/HOPPSCOTCH_INSTALLATION_GUIDE.md
# ... (repeat for all files)

# Make scripts executable
chmod +x basic-setup/start.sh
chmod +x email-setup/start.sh
chmod +x aio-setup/start.sh
chmod +x ec2-setup.sh
chmod +x deploy-ecs-rds.sh
```

### Option 2: Git Repository Structure
```bash
git init hoppscotch-self-hosted
cd hoppscotch-self-hosted

# Create directory structure
mkdir -p {basic-setup,email-setup,aio-setup}

# Add all files (copy from this guide)
# Commit structure
git add .
git commit -m "Initial Hoppscotch self-hosted setup"
```

### Option 3: Archive Download
Create a complete archive:
```bash
tar -czf hoppscotch-self-hosted.tar.gz \
    README.md \
    HOPPSCOTCH_INSTALLATION_GUIDE.md \
    EC2_DEPLOYMENT_GUIDE.md \
    ECS_DEPLOYMENT_GUIDE.md \
    RDS_CONFIGURATION_GUIDE.md \
    SMTP_EXAMPLES.md \
    basic-setup/ \
    email-setup/ \
    aio-setup/ \
    ec2-setup.sh \
    deploy-ecs-rds.sh \
    cloudformation-ecs-rds.yaml
```

## 📝 File Contents Summary

### Environment Files (.env)

#### Basic Setup
```env
DATABASE_URL=postgresql://hoppscotch:hoppscotchpassword@postgres:5432/hoppscotchdb
DATA_ENCRYPTION_KEY=ReplaceWith32CharacterSecret1234
VITE_BASE_URL=http://localhost:3000
VITE_ADMIN_URL=http://localhost:3100
VITE_BACKEND_GQL_URL=http://localhost:3170/graphql
VITE_BACKEND_WS_URL=ws://localhost:3170/graphql
VITE_BACKEND_API_URL=http://localhost:3170/v1
WHITELISTED_ORIGINS=http://localhost:3170,http://localhost:3000,http://localhost:3100,app://localhost_3200,app://hoppscotch
ENABLE_SUBPATH_BASED_ACCESS=true
```

#### Email Setup (Additional)
```env
MAILER_SMTP_URL=smtp://mailhog:1025
MAILER_ADDRESS_FROM=noreply@hoppscotch.local
```

#### EC2 Setup (Replace YOUR_EC2_PUBLIC_IP)
```env
VITE_BASE_URL=http://YOUR_EC2_PUBLIC_IP:3000
VITE_ADMIN_URL=http://YOUR_EC2_PUBLIC_IP:3100
VITE_BACKEND_GQL_URL=http://YOUR_EC2_PUBLIC_IP:3170/graphql
WHITELISTED_ORIGINS=http://YOUR_EC2_PUBLIC_IP:3170,http://YOUR_EC2_PUBLIC_IP:3000,http://YOUR_EC2_PUBLIC_IP:3100,http://YOUR_EC2_PUBLIC_IP,https://YOUR_EC2_PUBLIC_IP,app://localhost_3200,app://hoppscotch
```

### Docker Compose Files

#### Basic Structure
```yaml
version: "3.8"
services:
  postgres:
    image: postgres:15-alpine
    # ... configuration
  
  frontend:
    image: hoppscotch/hoppscotch-frontend
    ports:
      - "3000:3000"
      - "3200:3200"  # Desktop app support
    # ... configuration
  
  backend:
    image: hoppscotch/hoppscotch-backend
    ports:
      - "3170:3170"
    # ... configuration
  
  admin:
    image: hoppscotch/hoppscotch-admin
    ports:
      - "3100:3100"
    # ... configuration
```

#### With Email (Additional)
```yaml
  mailhog:
    image: mailhog/mailhog
    ports:
      - "1025:1025"  # SMTP
      - "8025:8025"  # Web UI
```

## 🔧 Customization Guide

### For Different Environments

#### Development
- Use `basic-setup/` or `email-setup/`
- Small resource allocation
- No SSL/HTTPS required
- Local database

#### Staging
- Use `ec2-setup.sh` with staging domain
- Medium resource allocation
- SSL recommended
- Can use RDS or local database

#### Production
- Use `deploy-ecs-rds.sh`
- Auto-scaling enabled
- SSL required
- Managed RDS database
- Multi-AZ deployment

### Port Customization
Default ports can be changed in docker-compose.yml:
```yaml
ports:
  - "8080:3000"  # Change 8080 to your preferred port
```

### Domain Customization
Update .env files with your domain:
```env
VITE_BASE_URL=https://yourdomain.com
VITE_ADMIN_URL=https://yourdomain.com/admin
```

## 🆘 Troubleshooting File Issues

### Missing Files
```bash
# Check if all files exist
ls -la basic-setup/
ls -la email-setup/
ls -la aio-setup/
```

### Permission Issues
```bash
# Fix script permissions
chmod +x *.sh
chmod +x */start.sh
```

### Environment Issues
```bash
# Validate .env files
cat basic-setup/.env | grep -v "^#" | grep "="
```

## 📚 Additional Resources

- **Official Hoppscotch Docs**: https://docs.hoppscotch.io/
- **Docker Documentation**: https://docs.docker.com/
- **AWS ECS Documentation**: https://docs.aws.amazon.com/ecs/
- **AWS RDS Documentation**: https://docs.aws.amazon.com/rds/

---

*This file structure supports all deployment scenarios from local development to production-grade AWS deployments.*
