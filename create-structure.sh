#!/bin/bash

echo "🏗️  Creating Hoppscotch Self-Hosted Complete Structure"
echo "===================================================="

# Create base directory
BASE_DIR="hoppscotch-self-hosted"
echo "📁 Creating base directory: $BASE_DIR"

if [ -d "$BASE_DIR" ]; then
    echo "⚠️  Directory $BASE_DIR already exists. Remove it? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        rm -rf "$BASE_DIR"
        echo "🗑️  Removed existing directory"
    else
        echo "❌ Aborted"
        exit 1
    fi
fi

mkdir -p "$BASE_DIR"
cd "$BASE_DIR"

# Create directory structure
echo "📂 Creating directory structure..."
mkdir -p {basic-setup,email-setup,aio-setup,aws-deployments,docs}

echo "📋 Copying documentation files..."
# Copy documentation
cp ../README.md ./
cp ../HOPPSCOTCH_INSTALLATION_GUIDE.md ./docs/
cp ../EC2_DEPLOYMENT_GUIDE.md ./docs/
cp ../ECS_DEPLOYMENT_GUIDE.md ./docs/
cp ../RDS_CONFIGURATION_GUIDE.md ./docs/
cp ../SMTP_EXAMPLES.md ./docs/
cp ../FILE_STRUCTURE.md ./

echo "🐳 Copying setup directories..."
# Copy setup directories
cp -r ../basic-setup/* ./basic-setup/
cp -r ../email-setup/* ./email-setup/
cp -r ../aio-setup/* ./aio-setup/

echo "☁️  Copying AWS deployment files..."
# Copy AWS deployment files
cp ../ec2-setup.sh ./aws-deployments/
cp ../deploy-ecs-rds.sh ./aws-deployments/
cp ../cloudformation-ecs-rds.yaml ./aws-deployments/

echo "🔧 Setting permissions..."
# Make scripts executable
chmod +x basic-setup/start.sh
chmod +x email-setup/start.sh
chmod +x aio-setup/start.sh
chmod +x aws-deployments/ec2-setup.sh
chmod +x aws-deployments/deploy-ecs-rds.sh

# Create a comprehensive README for the structure
cat > STRUCTURE_README.md << 'EOF'
# Hoppscotch Self-Hosted Complete Package

This package contains everything you need to deploy Hoppscotch in various environments.

## 🚀 Quick Start

### Local Development
```bash
# Basic setup (no email)
cd basic-setup && ./start.sh

# With email support  
cd email-setup && ./start.sh

# All-in-One container
cd aio-setup && ./start.sh
```

### AWS Production
```bash
# EC2 deployment
cd aws-deployments && ./ec2-setup.sh

# ECS + RDS deployment
cd aws-deployments && ./deploy-ecs-rds.sh
```

## 📁 Directory Structure

- `basic-setup/` - Local development without email
- `email-setup/` - Local development with MailHog email
- `aio-setup/` - All-in-One container setup
- `aws-deployments/` - AWS deployment scripts and templates
- `docs/` - Complete documentation
- `README.md` - Main overview
- `FILE_STRUCTURE.md` - Detailed file structure guide

## 📚 Documentation

- Read `README.md` for overview
- Check `docs/HOPPSCOTCH_INSTALLATION_GUIDE.md` for complete guide
- See `docs/EC2_DEPLOYMENT_GUIDE.md` for EC2 deployment
- See `docs/ECS_DEPLOYMENT_GUIDE.md` for ECS deployment
- Check `docs/SMTP_EXAMPLES.md` for email configuration

## 🆘 Support

- Official Docs: https://docs.hoppscotch.io/
- GitHub: https://github.com/hoppscotch/hoppscotch
- Issues: https://github.com/hoppscotch/hoppscotch/issues
EOF

# Create a simple deployment guide
cat > DEPLOYMENT_GUIDE.md << 'EOF'
# Quick Deployment Guide

## 1. Choose Your Deployment Type

### Local Development
- **Basic**: No email features, simple API testing
- **Email**: Full features with email testing via MailHog
- **AIO**: Single container, good for demos

### Production
- **EC2**: Single server with public IP
- **ECS + RDS**: Scalable, managed, production-grade

## 2. Prerequisites

### Local Development
- Docker and Docker Compose
- 4GB+ RAM
- Ports 3000, 3100, 3170, 5432 available

### AWS Production
- AWS CLI configured
- AWS account with appropriate permissions
- Domain name (for ECS deployment)
- SSL certificate (for ECS deployment)

## 3. Deployment Commands

### Local
```bash
# Choose one:
cd basic-setup && ./start.sh
cd email-setup && ./start.sh  
cd aio-setup && ./start.sh
```

### AWS
```bash
# Choose one:
cd aws-deployments && ./ec2-setup.sh
cd aws-deployments && ./deploy-ecs-rds.sh
```

## 4. Access URLs

### Local
- Frontend: http://localhost:3000
- Admin: http://localhost:3100
- MailHog: http://localhost:8025 (email setup only)

### AWS
- EC2: http://YOUR_EC2_IP:3000
- ECS: https://your-domain.com

## 5. First Steps After Deployment

1. Access the admin panel
2. Create your first admin user via magic link
3. Configure your API collections
4. Start testing APIs!

For detailed instructions, see the documentation in the `docs/` folder.
EOF

# Create version info
cat > VERSION.md << 'EOF'
# Version Information

- **Package Version**: 1.0.0
- **Hoppscotch Version**: Latest (Community Edition)
- **Docker Images**: 
  - hoppscotch/hoppscotch-frontend:latest
  - hoppscotch/hoppscotch-backend:latest
  - hoppscotch/hoppscotch-admin:latest
  - hoppscotch/hoppscotch:latest (AIO)
- **PostgreSQL Version**: 15-alpine
- **MailHog Version**: latest

## Supported Platforms

- **Local**: Docker Desktop (Windows, macOS, Linux)
- **Cloud**: AWS (EC2, ECS, RDS)
- **Architectures**: x86_64, ARM64

## Last Updated

Generated on: $(date)
EOF

echo ""
echo "✅ Structure created successfully!"
echo ""
echo "📁 Directory: $BASE_DIR/"
echo "📊 Total files: $(find . -type f | wc -l)"
echo "📦 Total size: $(du -sh . | cut -f1)"
echo ""
echo "🚀 Next steps:"
echo "   1. cd $BASE_DIR"
echo "   2. Read STRUCTURE_README.md"
echo "   3. Choose your deployment type"
echo "   4. Follow the quick start guide"
echo ""
echo "📚 Documentation available in:"
echo "   - README.md (overview)"
echo "   - DEPLOYMENT_GUIDE.md (quick guide)"
echo "   - docs/ (detailed guides)"
echo ""

# Create a simple tree view
echo "📂 Directory structure:"
if command -v tree &> /dev/null; then
    tree -a -I '.git'
else
    find . -type d | sed -e "s/[^-][^\/]*\// |/g" -e "s/|\([^ ]\)/|-\1/"
fi

echo ""
echo "🎉 Complete Hoppscotch self-hosted package ready!"
echo "   Package location: $(pwd)"
EOF
