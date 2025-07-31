# Complete Hoppscotch Self-Hosted File List

This document lists every file in the complete Hoppscotch self-hosted package with descriptions and usage.

## 📋 All Files Overview

### 📚 Documentation Files (7 files)
| File | Size | Purpose |
|------|------|---------|
| `README.md` | ~8KB | Main overview with quick start options |
| `HOPPSCOTCH_INSTALLATION_GUIDE.md` | ~25KB | Complete installation guide with troubleshooting |
| `EC2_DEPLOYMENT_GUIDE.md` | ~15KB | AWS EC2 deployment with public IP access |
| `ECS_DEPLOYMENT_GUIDE.md` | ~20KB | AWS ECS with Fargate and auto-scaling |
| `RDS_CONFIGURATION_GUIDE.md` | ~18KB | RDS PostgreSQL setup and optimization |
| `SMTP_EXAMPLES.md` | ~8KB | Email provider configurations |
| `FILE_STRUCTURE.md` | ~6KB | Complete file structure documentation |

### 🐳 Local Development Setups (9 files)

#### Basic Setup (3 files)
| File | Purpose |
|------|---------|
| `basic-setup/docker-compose.yml` | PostgreSQL + Hoppscotch services |
| `basic-setup/.env` | Environment variables for basic setup |
| `basic-setup/start.sh` | One-click startup script |

#### Email Setup (3 files)
| File | Purpose |
|------|---------|
| `email-setup/docker-compose.yml` | PostgreSQL + Hoppscotch + MailHog |
| `email-setup/.env` | Environment with SMTP configuration |
| `email-setup/start.sh` | One-click startup with email support |

#### AIO Setup (3 files)
| File | Purpose |
|------|---------|
| `aio-setup/docker-compose.yml` | PostgreSQL + All-in-One container |
| `aio-setup/.env` | AIO environment configuration |
| `aio-setup/start.sh` | AIO startup script |

### ☁️ AWS Deployment Files (3 files)
| File | Size | Purpose |
|------|------|---------|
| `ec2-setup.sh` | ~3KB | EC2 one-click deployment script |
| `deploy-ecs-rds.sh` | ~8KB | ECS + RDS interactive deployment |
| `cloudformation-ecs-rds.yaml` | ~15KB | Complete infrastructure template |

### ⚙️ Utility Files (4 files)
| File | Purpose |
|------|---------|
| `create-structure.sh` | Generate complete organized structure |
| `COMPLETE_FILE_LIST.md` | This file - complete file listing |
| `.env` | Current working environment file |
| `docker-compose.yml` | Current working compose file |

## 📁 Organized Structure (Recommended)

When you run `./create-structure.sh`, it creates this organized structure:

```
hoppscotch-self-hosted/
├── README.md                           # Main overview
├── FILE_STRUCTURE.md                   # Structure guide
├── STRUCTURE_README.md                 # Package overview
├── DEPLOYMENT_GUIDE.md                 # Quick deployment guide
├── VERSION.md                          # Version information
│
├── docs/                               # All documentation
│   ├── HOPPSCOTCH_INSTALLATION_GUIDE.md
│   ├── EC2_DEPLOYMENT_GUIDE.md
│   ├── ECS_DEPLOYMENT_GUIDE.md
│   ├── RDS_CONFIGURATION_GUIDE.md
│   └── SMTP_EXAMPLES.md
│
├── basic-setup/                        # Local development (no email)
│   ├── docker-compose.yml
│   ├── .env
│   └── start.sh
│
├── email-setup/                        # Local development (with email)
│   ├── docker-compose.yml
│   ├── .env
│   └── start.sh
│
├── aio-setup/                          # All-in-One container
│   ├── docker-compose.yml
│   ├── .env
│   └── start.sh
│
└── aws-deployments/                    # AWS production deployments
    ├── ec2-setup.sh
    ├── deploy-ecs-rds.sh
    └── cloudformation-ecs-rds.yaml
```

## 🚀 Usage Instructions

### Step 1: Create Organized Structure
```bash
./create-structure.sh
cd hoppscotch-self-hosted
```

### Step 2: Choose Deployment Type
```bash
# Local development (choose one)
cd basic-setup && ./start.sh      # No email
cd email-setup && ./start.sh      # With email
cd aio-setup && ./start.sh        # All-in-One

# AWS production (choose one)
cd aws-deployments && ./ec2-setup.sh        # Single EC2 instance
cd aws-deployments && ./deploy-ecs-rds.sh   # Scalable ECS + RDS
```

## 📝 File Contents Summary

### Environment Variables (.env files)

#### Common Variables (All Setups)
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

#### Email Setup Additional Variables
```env
MAILER_SMTP_URL=smtp://mailhog:1025
MAILER_ADDRESS_FROM=noreply@hoppscotch.local
```

#### EC2 Setup Variables (Replace YOUR_EC2_PUBLIC_IP)
```env
VITE_BASE_URL=http://YOUR_EC2_PUBLIC_IP:3000
VITE_ADMIN_URL=http://YOUR_EC2_PUBLIC_IP:3100
VITE_BACKEND_GQL_URL=http://YOUR_EC2_PUBLIC_IP:3170/graphql
WHITELISTED_ORIGINS=http://YOUR_EC2_PUBLIC_IP:3170,http://YOUR_EC2_PUBLIC_IP:3000,http://YOUR_EC2_PUBLIC_IP:3100,http://YOUR_EC2_PUBLIC_IP,https://YOUR_EC2_PUBLIC_IP,app://localhost_3200,app://hoppscotch
```

### Docker Compose Services

#### Core Services (All Setups)
- **postgres**: PostgreSQL 15-alpine database
- **frontend**: Hoppscotch frontend (ports 3000, 3200)
- **backend**: Hoppscotch backend (port 3170)
- **admin**: Hoppscotch admin panel (port 3100)

#### Additional Services
- **mailhog**: Email testing (ports 1025, 8025) - Email setup only
- **hoppscotch-aio**: All-in-One container - AIO setup only

### Script Functions

#### start.sh Scripts
- Pull latest Docker images
- Start services with docker-compose
- Wait for initialization
- Run database migrations
- Display access URLs and instructions

#### ec2-setup.sh
- Auto-detect EC2 public IP
- Generate EC2-specific configuration
- Deploy with public access
- Configure security groups
- Display access information

#### deploy-ecs-rds.sh
- Interactive configuration gathering
- SSL certificate validation
- CloudFormation stack deployment
- Database migration execution
- Comprehensive error handling

## 🔧 Customization Options

### Port Changes
Edit docker-compose.yml files:
```yaml
ports:
  - "8080:3000"  # Change external port
```

### Domain Changes
Edit .env files:
```env
VITE_BASE_URL=https://yourdomain.com
```

### Resource Limits
Add to docker-compose.yml:
```yaml
deploy:
  resources:
    limits:
      memory: 1G
      cpus: '0.5'
```

## 📊 File Statistics

- **Total Files**: 23
- **Documentation**: 7 files (~100KB)
- **Setup Configurations**: 9 files (~15KB)
- **AWS Deployments**: 3 files (~26KB)
- **Utility Scripts**: 4 files (~10KB)
- **Total Package Size**: ~150KB

## 🎯 Deployment Matrix

| Use Case | Setup Type | Files Needed | Complexity |
|----------|------------|--------------|------------|
| API Testing | basic-setup | 3 files | ⭐ Simple |
| Full Development | email-setup | 3 files | ⭐⭐ Easy |
| Demo/Presentation | aio-setup | 3 files | ⭐ Simple |
| Small Production | EC2 | 1 script + docs | ⭐⭐⭐ Medium |
| Enterprise Production | ECS + RDS | 2 files + docs | ⭐⭐⭐⭐ Advanced |

## 🆘 Quick Troubleshooting

### File Missing
```bash
# Check if all files exist
ls -la basic-setup/
ls -la email-setup/
ls -la aio-setup/
ls -la aws-deployments/
```

### Permission Issues
```bash
# Fix all script permissions
find . -name "*.sh" -exec chmod +x {} \;
```

### Environment Issues
```bash
# Validate environment files
grep -v "^#" */\.env | grep "="
```

## 📚 Additional Resources

- **Official Documentation**: https://docs.hoppscotch.io/
- **GitHub Repository**: https://github.com/hoppscotch/hoppscotch
- **Docker Hub**: https://hub.docker.com/u/hoppscotch
- **AWS Documentation**: https://docs.aws.amazon.com/

---

*This complete package provides everything needed for Hoppscotch deployment from local development to production-grade AWS infrastructure.*
