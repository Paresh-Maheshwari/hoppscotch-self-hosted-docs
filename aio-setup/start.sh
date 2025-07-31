#!/bin/bash

echo "🚀 Starting Hoppscotch (AIO Container)"
echo "======================================"

# Pull latest AIO image
echo "📦 Pulling latest Hoppscotch AIO image..."
docker pull hoppscotch/hoppscotch

# Start services
echo "📦 Starting Docker containers..."
docker compose up -d

# Wait for services
echo "⏳ Waiting for services to initialize..."
sleep 30

# Run migrations
echo "🔄 Running database migrations..."
docker compose run --rm hoppscotch-aio pnpm dlx prisma migrate deploy

echo ""
echo "✅ Hoppscotch AIO is ready!"
echo ""
echo "🌐 Access URLs (Subpath Access Enabled):"
echo "   Frontend:     http://localhost:3000/"
echo "   Admin Panel:  http://localhost:3000/admin"
echo "   Backend API:  http://localhost:3000/backend"
echo ""
echo "📱 Desktop App Support:"
echo "   • Subpath access enabled"
echo "   • Desktop app can connect to this instance"
echo "   • Bundle server available"
echo ""
echo "⚙️  Alternative Access (Individual Ports):"
echo "   Frontend:     http://localhost:3000"
echo "   Admin Panel:  http://localhost:3100"
echo "   Backend API:  http://localhost:3170"
echo ""
echo "👤 Create Admin User:"
echo "   1. Go to http://localhost:3100"
echo "   2. Enter any email (e.g., admin@example.com)"
echo "   3. Use magic link authentication"
echo ""
echo "🛑 To stop: docker compose down"
echo "🔄 To restart: docker compose restart"
