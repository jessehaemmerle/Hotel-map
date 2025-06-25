#!/bin/bash

# Frontend Docker Container Restart Diagnostics and Fixes
echo "🐳 Frontend Container Restart Issue Analysis"
echo "============================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✅ FIX]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠️  ISSUE]${NC} $1"
}

print_error() {
    echo -e "${RED}[❌ ERROR]${NC} $1"
}

echo ""
print_status "Analyzing potential frontend container restart causes..."

# Issue 1: Backend URL configuration
echo ""
print_status "1. Checking backend URL configuration..."
if grep -q "REACT_APP_BACKEND_URL=http://localhost:7070" docker-compose.yml; then
    print_error "CRITICAL: Frontend is configured to call localhost:7070 (itself) instead of backend"
    print_status "The frontend container cannot reach 'localhost:7070' for API calls"
    print_status "It should call the backend service: http://hotel-mapping-backend:8001"
elif grep -q "REACT_APP_BACKEND_URL=http://localhost:8001" docker-compose.yml; then
    print_error "CRITICAL: Frontend is configured to call localhost:8001, but should use service name"
    print_status "In Docker, services communicate via service names, not localhost"
else
    print_success "Backend URL configuration looks correct"
fi

# Issue 2: Environment variable inheritance
echo ""
print_status "2. Checking environment variable setup..."
if [[ -f "frontend/.env" ]]; then
    if grep -q "REACT_APP_BACKEND_URL=http://localhost:8001" frontend/.env; then
        print_warning "Frontend .env has localhost URL - this will override Docker build args"
        print_status "React prioritizes .env files over build arguments"
    fi
fi

# Issue 3: Build context issues
echo ""
print_status "3. Checking Dockerfile.frontend build context..."
if grep -q "COPY frontend/package.json frontend/yarn.lock" Dockerfile.frontend; then
    print_success "Package files copying looks correct"
else
    print_error "Package file copy paths may be incorrect"
fi

if grep -q "COPY frontend/src ./src" Dockerfile.frontend; then
    print_success "Source code copying looks correct"
else
    print_error "Source code copy paths may be incorrect"
fi

# Issue 4: Health check configuration
echo ""
print_status "4. Checking health check configuration..."
if grep -q "curl -f http://localhost:7070" Dockerfile.frontend; then
    print_success "Health check URL looks correct"
else
    print_warning "Health check may have URL issues"
fi

# Issue 5: Node.js version compatibility
echo ""
print_status "5. Checking Node.js version..."
if grep -q "FROM node:21-alpine" Dockerfile.frontend; then
    print_warning "Using Node.js 21 - very latest version, may have compatibility issues"
    print_status "Recommend using Node.js 20 LTS for better stability"
else
    print_success "Node.js version looks stable"
fi

# Issue 6: Build process issues
echo ""
print_status "6. Checking build process..."
if grep -q "yarn build" Dockerfile.frontend; then
    print_success "Build command present"
    if [[ -f "frontend/package.json" ]]; then
        if grep -q '"build":' frontend/package.json; then
            print_success "Build script defined in package.json"
        else
            print_error "Build script missing in package.json"
        fi
    fi
else
    print_error "Build command missing in Dockerfile"
fi

# Issue 7: Port configuration
echo ""
print_status "7. Checking port configuration..."
if grep -q "listen 7070" nginx.conf && grep -q "EXPOSE 7070" Dockerfile.frontend; then
    print_success "Port 7070 consistently configured"
else
    print_error "Port configuration mismatch between nginx and Dockerfile"
fi

echo ""
echo "🔧 RECOMMENDED FIXES FOR CONTAINER RESTART ISSUES"
echo "================================================="

echo ""
print_status "Issue: Frontend tries to call localhost instead of backend service"
echo "Fix: Update docker-compose.yml frontend environment:"
echo "     REACT_APP_BACKEND_URL=http://hotel-mapping-backend:8001"

echo ""
print_status "Issue: .env file overrides Docker build arguments"
echo "Fix: Update frontend/.env to use container service name:"
echo "     REACT_APP_BACKEND_URL=http://hotel-mapping-backend:8001"

echo ""
print_status "Issue: Node.js 21 compatibility"
echo "Fix: Use Node.js 20 LTS in Dockerfile.frontend:"
echo "     FROM node:20-alpine AS builder"

echo ""
print_status "Issue: Health check failures causing restarts"
echo "Fix: Add fallback health check in Dockerfile.frontend:"
echo "     CMD curl -f http://localhost:7070/health || curl -f http://localhost:7070 || exit 1"

echo ""
echo "🚀 DEPLOYMENT COMMANDS AFTER FIXES"
echo "=================================="
echo "1. Apply the fixes above"
echo "2. Run: ./deploy.sh dev"
echo "3. Monitor logs: docker-compose logs -f frontend"

echo ""
echo "📋 QUICK DIAGNOSTIC COMMANDS"
echo "============================"
echo "Check container status: docker-compose ps"
echo "View frontend logs: docker-compose logs frontend"
echo "Check health: docker-compose exec frontend curl http://localhost:7070"
echo "Restart frontend: docker-compose restart frontend"