#!/bin/bash

echo "🚀 Starting Hoppscotch (Basic Setup - No Email)"
echo "================================================"

# Start services
echo "📦 Starting Docker containers..."
docker compose up -d

# Wait for PostgreSQL
echo "⏳ Waiting for PostgreSQL to initialize..."
sleep 30

# Run migrations
echo "🔄 Running database migrations..."
docker compose run --rm backend pnpm dlx prisma migrate deploy

echo ""
echo "✅ Hoppscotch is ready!"
echo ""
echo "🌐 Access URLs:"
echo "   Frontend:    http://localhost:3000"
echo "   Admin Panel: http://localhost:3100"
echo "   Backend API: http://localhost:3170"
echo ""
echo "📝 Note: Email authentication is not available in this setup"
echo "   Use the frontend at http://localhost:3000 for API testing"
echo ""
echo "🛑 To stop: docker compose down"
echo "🔄 To restart: docker compose restart"
