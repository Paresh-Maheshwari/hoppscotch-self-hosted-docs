#!/bin/bash

echo "🚀 Starting Hoppscotch (With Email Support)"
echo "============================================"

# Start services
echo "📦 Starting Docker containers..."
docker compose up -d

# Wait for services
echo "⏳ Waiting for services to initialize..."
sleep 30

# Run migrations
echo "🔄 Running database migrations..."
docker compose run --rm backend pnpm dlx prisma migrate deploy

echo ""
echo "✅ Hoppscotch is ready!"
echo ""
echo "🌐 Access URLs:"
echo "   Frontend:     http://localhost:3000"
echo "   Admin Panel:  http://localhost:3100"
echo "   Backend API:  http://localhost:3170"
echo "   MailHog UI:   http://localhost:8025"
echo ""
echo "📧 Email Features:"
echo "   • Magic link authentication available"
echo "   • All emails captured in MailHog"
echo "   • SMTP server: localhost:1025"
echo ""
echo "👤 Create Admin User:"
echo "   1. Go to http://localhost:3100"
echo "   2. Enter any email (e.g., admin@example.com)"
echo "   3. Check http://localhost:8025 for magic link"
echo "   4. Click the magic link to sign in"
echo ""
echo "🛑 To stop: docker compose down"
echo "🔄 To restart: docker compose restart"
