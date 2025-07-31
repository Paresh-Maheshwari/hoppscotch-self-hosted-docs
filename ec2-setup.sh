#!/bin/bash

echo "🚀 Hoppscotch EC2 Deployment Setup"
echo "=================================="

# Get EC2 public IP
echo "📡 Getting EC2 public IP..."
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)

if [ -z "$PUBLIC_IP" ]; then
    echo "❌ Could not detect EC2 public IP. Please enter manually:"
    read -p "Enter your EC2 public IP: " PUBLIC_IP
fi

echo "✅ Using public IP: $PUBLIC_IP"

# Create .env file with EC2 public IP
echo "📝 Creating .env file with EC2 configuration..."
cat > .env << EOF
#-----------------------Backend Config------------------------------#

# Prisma Config
DATABASE_URL=postgresql://hoppscotch:hoppscotchpassword@postgres:5432/hoppscotchdb

# Sensitive Data Encryption Key (32 characters) - CHANGE IN PRODUCTION
DATA_ENCRYPTION_KEY=ReplaceWith32CharacterSecret1234

# Whitelisted origins for cross-origin communication
WHITELISTED_ORIGINS=http://${PUBLIC_IP}:3170,http://${PUBLIC_IP}:3000,http://${PUBLIC_IP}:3100,http://${PUBLIC_IP},https://${PUBLIC_IP},app://localhost_3200,app://hoppscotch

# SMTP Configuration (MailHog for development)
MAILER_SMTP_URL=smtp://mailhog:1025
MAILER_ADDRESS_FROM=noreply@hoppscotch.local

#-----------------------Frontend Config------------------------------#

# Base URLs
VITE_BASE_URL=http://${PUBLIC_IP}:3000
VITE_SHORTCODE_BASE_URL=http://${PUBLIC_IP}:3000
VITE_ADMIN_URL=http://${PUBLIC_IP}:3100

# Backend URLs
VITE_BACKEND_GQL_URL=http://${PUBLIC_IP}:3170/graphql
VITE_BACKEND_WS_URL=ws://${PUBLIC_IP}:3170/graphql
VITE_BACKEND_API_URL=http://${PUBLIC_IP}:3170/v1

# Terms Of Service And Privacy Policy Links (Optional)
VITE_APP_TOS_LINK=https://docs.hoppscotch.io/support/terms
VITE_APP_PRIVACY_POLICY_LINK=https://docs.hoppscotch.io/support/privacy

# Desktop App Support
ENABLE_SUBPATH_BASED_ACCESS=true
EOF

# Create docker-compose.yml for EC2
echo "🐳 Creating docker-compose.yml for EC2..."
cat > docker-compose.yml << 'EOF'
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
EOF

# Pull Docker images
echo "📦 Pulling Docker images..."
docker-compose pull

# Start services
echo "🚀 Starting Hoppscotch services..."
docker-compose up -d

# Wait for services to start
echo "⏳ Waiting for services to initialize..."
sleep 30

# Run database migrations
echo "🔄 Running database migrations..."
docker-compose run --rm backend pnpm dlx prisma migrate deploy

echo ""
echo "✅ Hoppscotch EC2 deployment complete!"
echo ""
echo "🌐 Access URLs:"
echo "   Frontend:     http://${PUBLIC_IP}:3000"
echo "   Frontend:     http://${PUBLIC_IP} (port 80)"
echo "   Admin Panel:  http://${PUBLIC_IP}:3100"
echo "   Backend API:  http://${PUBLIC_IP}:3170"
echo "   MailHog UI:   http://${PUBLIC_IP}:8025"
echo ""
echo "🔐 Security Group Requirements:"
echo "   - Port 80 (HTTP)"
echo "   - Port 3000 (Frontend)"
echo "   - Port 3100 (Admin)"
echo "   - Port 3170 (Backend)"
echo "   - Port 3200 (Desktop App)"
echo "   - Port 8025 (MailHog - Optional)"
echo ""
echo "👤 Create Admin User:"
echo "   1. Go to http://${PUBLIC_IP}:3100"
echo "   2. Enter any email (e.g., admin@example.com)"
echo "   3. Check http://${PUBLIC_IP}:8025 for magic link"
echo "   4. Click the magic link to sign in"
echo ""
echo "🛑 To stop: docker-compose down"
echo "🔄 To restart: docker-compose restart"
echo ""
echo "📚 For SSL/HTTPS setup, see EC2_DEPLOYMENT_GUIDE.md"
EOF
