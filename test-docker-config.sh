#!/bin/bash

# Test script for Docker configuration
echo "🏨 Testing Hotel Mapping Docker Configuration"
echo "=============================================="

# Check if all required files exist
echo "📁 Checking Docker files..."
files=("docker-compose.yml" "Dockerfile.frontend" "Dockerfile.backend" "nginx.conf" ".env")
for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
        exit 1
    fi
done

# Check environment variables
echo ""
echo "🔧 Checking environment configuration..."
if grep -q "MAPBOX_ACCESS_TOKEN=pk\..*" .env; then
    echo "✅ Mapbox token configured"
else
    echo "❌ Mapbox token not configured"
    exit 1
fi

if grep -q "JWT_SECRET=.*" .env; then
    echo "✅ JWT secret configured"
else
    echo "❌ JWT secret not configured"
    exit 1
fi

# Check port configuration
echo ""
echo "🚢 Checking port configuration..."
if grep -q "7070:7070" docker-compose.yml; then
    echo "✅ Frontend port 7070 configured in docker-compose.yml"
else
    echo "❌ Frontend port 7070 not configured in docker-compose.yml"
    exit 1
fi

if grep -q "listen 7070" nginx.conf; then
    echo "✅ Nginx listening on port 7070"
else
    echo "❌ Nginx not configured for port 7070"
    exit 1
fi

if grep -q "EXPOSE 7070" Dockerfile.frontend; then
    echo "✅ Frontend Dockerfile exposes port 7070"
else
    echo "❌ Frontend Dockerfile doesn't expose port 7070"
    exit 1
fi

# Check backend configuration
echo ""
echo "⚙️ Checking backend configuration..."
if [[ -f "backend/.env" && -f "backend/.env.docker" ]]; then
    echo "✅ Backend environment files exist"
else
    echo "❌ Backend environment files missing"
    exit 1
fi

if grep -q "8001:8001" docker-compose.yml; then
    echo "✅ Backend port 8001 configured"
else
    echo "❌ Backend port 8001 not configured"
    exit 1
fi

if grep -q "27013:27017" docker-compose.yml; then
    echo "✅ MongoDB port 27013 configured"
else
    echo "❌ MongoDB port 27013 not configured"
    exit 1
fi

echo ""
echo "🎉 All Docker configuration checks passed!"
echo ""
echo "Your application is ready to deploy on port 7070!"
echo ""
echo "To deploy, run:"
echo "  ./deploy.sh dev    # For development"
echo "  ./deploy.sh prod   # For production"
echo ""
echo "Access URLs after deployment:"
echo "  Frontend: http://localhost:7070"
echo "  Backend API: http://localhost:8001"
echo "  MongoDB: localhost:27013"
echo "  API Docs: http://localhost:8001/docs"