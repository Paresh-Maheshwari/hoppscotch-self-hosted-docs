# Hoppscotch Self-Hosted Setup

This directory contains complete setup files for running Hoppscotch Community Edition in a self-hosted environment.

## 📁 Directory Structure

```
├── HOPPSCOTCH_INSTALLATION_GUIDE.md  # Complete installation guide
├── EC2_DEPLOYMENT_GUIDE.md           # AWS EC2 deployment guide
├── SMTP_EXAMPLES.md                  # Production SMTP configurations
├── basic-setup/                      # Individual containers (no email)
│   ├── docker-compose.yml
│   ├── .env
│   └── start.sh
├── email-setup/                      # Individual containers (with email)
│   ├── docker-compose.yml
│   ├── .env
│   └── start.sh
├── aio-setup/                        # All-in-One container
│   ├── docker-compose.yml
│   ├── .env
│   └── start.sh
├── ec2-setup.sh                      # AWS EC2 one-click setup
└── README.md                         # This file
```

## 🚀 Quick Start Options

### Option 1: Basic Setup (Individual Containers, No Email)
```bash
cd basic-setup/
./start.sh
```
- **Use case**: API testing, development
- **Access**: http://localhost:3000
- **Desktop app**: ✅ Supported

### Option 2: Email Setup (Individual Containers, With Email)
```bash
cd email-setup/
./start.sh
```
- **Use case**: Full featured with user management
- **Access**: http://localhost:3100 (Admin), http://localhost:8025 (Email UI)
- **Desktop app**: ✅ Supported

### Option 3: AIO Container (All-in-One)
```bash
cd aio-setup/
./start.sh
```
- **Use case**: Simple deployment, production
- **Access**: http://localhost:3000/ (Subpath routing)
- **Desktop app**: ✅ Supported

### Option 4: AWS EC2 Deployment (Public Access)
```bash
./ec2-setup.sh
```
- **Use case**: Production deployment with public IP
- **Access**: http://YOUR_EC2_PUBLIC_IP:3000
- **Desktop app**: ✅ Supported
- **Requirements**: EC2 instance with proper security groups

### Option 5: AWS ECS + RDS Deployment (Production Scale)
```bash
./deploy-ecs-rds.sh
```
- **Use case**: Production-grade scalable deployment
- **Access**: https://your-domain.com
- **Features**: Auto-scaling, managed database, load balancing
- **Requirements**: AWS account, domain, SSL certificate
- **Access**: https://your-domain.com
- **Features**: Auto-scaling, managed database, load balancing
- **Requirements**: AWS account, domain, SSL certificate

## 📖 Documentation

- **Complete Guide**: [HOPPSCOTCH_INSTALLATION_GUIDE.md](./HOPPSCOTCH_INSTALLATION_GUIDE.md)
- **EC2 Deployment**: [EC2_DEPLOYMENT_GUIDE.md](./EC2_DEPLOYMENT_GUIDE.md)
- **SMTP Configuration**: [SMTP_EXAMPLES.md](./SMTP_EXAMPLES.md)

## 🔧 Manual Setup

If you prefer manual setup:

1. Choose your setup type (basic, email, aio, or ec2)
2. Copy the files from the respective directory
3. Run the commands:
   ```bash
   docker compose up -d
   sleep 30
   docker compose run --rm <service_name> pnpm dlx prisma migrate deploy
   ```

## 📱 Desktop App Support

All setups include desktop app support with:
- ✅ `ENABLE_SUBPATH_BASED_ACCESS=true`
- ✅ Port 3200 exposed (individual containers)
- ✅ Proper CORS origins configured
- ✅ Bundle server support

## 🌐 Public Access Configurations

### Local Development
- **Localhost**: http://localhost:3000
- **Pinggy Tunnel**: https://your-tunnel.pinggy.link
- **ngrok**: https://your-id.ngrok.io

### Production Deployment
- **EC2 Public IP**: http://YOUR_EC2_PUBLIC_IP:3000
- **Custom Domain**: https://yourdomain.com
- **Load Balancer**: https://your-alb.region.elb.amazonaws.com

## 🆘 Troubleshooting

### Common Issues
- **Port conflicts**: Check if ports 3000, 3100, 3170, 5432 are free
- **Email not working**: Ensure MailHog container is running
- **Desktop app issues**: Verify `ENABLE_SUBPATH_BASED_ACCESS=true`
- **Database errors**: Try clearing config: `docker exec -it hoppscotch-postgres psql -U hoppscotch -d hoppscotchdb -c "TRUNCATE \"InfraConfig\";"`
- **Public access issues**: Check security groups and firewall rules

### Migration Errors
If you see "Database migration not found":
```bash
# Run migrations manually
docker compose run --rm <service_name> pnpm dlx prisma migrate deploy
```

### Reset Everything
```bash
docker compose down
docker volume rm $(docker volume ls -q | grep pgdata)
docker compose up -d
sleep 30
docker compose run --rm <service_name> pnpm dlx prisma migrate deploy
```

## 📋 Default Ports

| Service | Port | URL | Notes |
|---------|------|-----|-------|
| Frontend | 3000 | http://localhost:3000 | Main app |
| Frontend (Alt) | 80 | http://localhost | Alternative access |
| Admin | 3100 | http://localhost:3100 | Admin panel |
| Backend | 3170 | http://localhost:3170 | API server |
| Desktop Bundle | 3200 | http://localhost:3200 | Desktop app support |
| PostgreSQL | 5432 | localhost:5432 | Database |
| MailHog SMTP | 1025 | localhost:1025 | Email server |
| MailHog UI | 8025 | http://localhost:8025 | Email viewer |

## 🔐 Security Notes

- Change `DATA_ENCRYPTION_KEY` in production (32 characters)
- Use strong PostgreSQL passwords
- Configure HTTPS with reverse proxy for production
- Regular backups recommended
- Never commit `.env` files to version control
- For EC2: Configure security groups properly
- For public access: Use SSL/TLS certificates

## 🌐 Production Deployment

For production:
1. Use strong passwords and encryption keys
2. Configure HTTPS with reverse proxy (nginx/traefik)
3. Use external PostgreSQL database (RDS recommended)
4. Configure real SMTP server (see SMTP_EXAMPLES.md)
5. Set up monitoring and backups
6. Use Docker secrets for sensitive data
7. Configure proper security groups (EC2)
8. Use Elastic IP for static public IP (EC2)

## 📚 Additional Resources

- **Official Docs**: https://docs.hoppscotch.io/
- **GitHub**: https://github.com/hoppscotch/hoppscotch
- **Issues**: https://github.com/hoppscotch/hoppscotch/issues
- **AWS EC2**: https://aws.amazon.com/ec2/
- **Docker**: https://docs.docker.com/

---

*For detailed instructions, see [HOPPSCOTCH_INSTALLATION_GUIDE.md](./HOPPSCOTCH_INSTALLATION_GUIDE.md)*
