#!/bin/bash

# Docker Deployment Readiness Check Script
echo "🔍 Docker Deployment Readiness Check"
echo "===================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✅ PASS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠️  WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[❌ FAIL]${NC} $1"
}

# Check if required files exist
echo ""
print_status "Checking required files for Docker deployment..."

# Check Docker files
if [[ -f "Dockerfile.backend" ]]; then
    print_success "Dockerfile.backend exists"
else
    print_error "Dockerfile.backend missing"
fi

if [[ -f "Dockerfile.frontend" ]]; then
    print_success "Dockerfile.frontend exists"
else
    print_error "Dockerfile.frontend missing"
fi

if [[ -f "docker-compose.yml" ]]; then
    print_success "docker-compose.yml exists"
else
    print_error "docker-compose.yml missing"
fi

# Check environment files
if [[ -f ".env" ]]; then
    print_success "Root .env file exists"
    # Check critical environment variables
    if grep -q "MAPBOX_ACCESS_TOKEN=" .env; then
        print_success "MAPBOX_ACCESS_TOKEN found in .env"
    else
        print_error "MAPBOX_ACCESS_TOKEN missing in .env"
    fi
    
    if grep -q "JWT_SECRET=" .env; then
        print_success "JWT_SECRET found in .env"
    else
        print_error "JWT_SECRET missing in .env"
    fi
else
    print_error "Root .env file missing"
fi

if [[ -f "backend/.env" ]]; then
    print_success "Backend .env file exists"
else
    print_error "Backend .env file missing"
fi

if [[ -f "frontend/.env" ]]; then
    print_success "Frontend .env file exists"
else
    print_error "Frontend .env file missing"
fi

# Check source code structure
echo ""
print_status "Checking source code structure..."

if [[ -f "backend/server.py" ]]; then
    print_success "Backend server.py exists"
else
    print_error "Backend server.py missing"
fi

if [[ -f "backend/requirements.txt" ]]; then
    print_success "Backend requirements.txt exists"
else
    print_error "Backend requirements.txt missing"
fi

if [[ -f "frontend/package.json" ]]; then
    print_success "Frontend package.json exists"
else
    print_error "Frontend package.json missing"
fi

if [[ -f "frontend/yarn.lock" ]]; then
    print_success "Frontend yarn.lock exists"
else
    print_warning "Frontend yarn.lock missing (may cause build issues)"
fi

# Check frontend source files
if [[ -f "frontend/src/App.js" ]]; then
    print_success "Frontend App.js exists"
else
    print_error "Frontend App.js missing"
fi

if [[ -d "frontend/public" ]]; then
    print_success "Frontend public directory exists"
else
    print_error "Frontend public directory missing"
fi

# Check required public files
if [[ -f "frontend/public/index.html" ]]; then
    print_success "Frontend index.html exists"
else
    print_error "Frontend index.html missing"
fi

if [[ -f "frontend/public/manifest.json" ]]; then
    print_success "Frontend manifest.json exists"
else
    print_warning "Frontend manifest.json missing (recommended for PWA)"
fi

# Check nginx configuration
if [[ -f "nginx.conf" ]]; then
    print_success "nginx.conf exists"
else
    print_error "nginx.conf missing"
fi

# Check deployment script
if [[ -f "deploy.sh" ]]; then
    print_success "deploy.sh exists"
    if [[ -x "deploy.sh" ]]; then
        print_success "deploy.sh is executable"
    else
        print_warning "deploy.sh is not executable (run: chmod +x deploy.sh)"
    fi
else
    print_error "deploy.sh missing"
fi

# Check if services are currently running
echo ""
print_status "Checking current service status..."

# Check if backend is responding
if curl -f http://localhost:8001/api/hotels >/dev/null 2>&1; then
    print_success "Backend API is responding on port 8001"
else
    print_warning "Backend API not responding on port 8001"
fi

# Check if frontend is responding
if curl -f http://localhost:7070 >/dev/null 2>&1; then
    print_success "Frontend is responding on port 7070"
else
    print_warning "Frontend not responding on port 7070"
fi

# Check MongoDB connection
if curl -f http://localhost:8001/api/auth/register >/dev/null 2>&1; then
    print_success "MongoDB connection appears to be working"
else
    print_warning "MongoDB connection may have issues"
fi

# Summarize Docker deployment readiness
echo ""
echo "📋 DOCKER DEPLOYMENT READINESS SUMMARY"
echo "======================================"

# Count files
total_checks=15
passed_checks=0

# Recheck critical files (simplified for summary)
[[ -f "Dockerfile.backend" ]] && ((passed_checks++))
[[ -f "Dockerfile.frontend" ]] && ((passed_checks++))
[[ -f "docker-compose.yml" ]] && ((passed_checks++))
[[ -f ".env" ]] && ((passed_checks++))
[[ -f "backend/.env" ]] && ((passed_checks++))
[[ -f "frontend/.env" ]] && ((passed_checks++))
[[ -f "backend/server.py" ]] && ((passed_checks++))
[[ -f "backend/requirements.txt" ]] && ((passed_checks++))
[[ -f "frontend/package.json" ]] && ((passed_checks++))
[[ -f "frontend/src/App.js" ]] && ((passed_checks++))
[[ -f "frontend/public/index.html" ]] && ((passed_checks++))
[[ -f "nginx.conf" ]] && ((passed_checks++))
[[ -f "deploy.sh" ]] && ((passed_checks++))

# Check environment variables
if [[ -f ".env" ]] && grep -q "MAPBOX_ACCESS_TOKEN=" .env && grep -q "JWT_SECRET=" .env; then
    ((passed_checks++))
fi

# Check if backend is responding
if curl -f http://localhost:8001/api/hotels >/dev/null 2>&1; then
    ((passed_checks++))
fi

echo "Passed: $passed_checks/$total_checks checks"

if [[ $passed_checks -ge 13 ]]; then
    print_success "Application is READY for Docker deployment! 🚀"
    echo ""
    echo "To deploy:"
    echo "  Development: ./deploy.sh dev"
    echo "  Production:  ./deploy.sh prod"
elif [[ $passed_checks -ge 10 ]]; then
    print_warning "Application is MOSTLY ready for Docker deployment with minor issues"
    echo ""
    echo "Fix the warnings above and then deploy with:"
    echo "  Development: ./deploy.sh dev"
else
    print_error "Application is NOT ready for Docker deployment"
    echo ""
    echo "Please fix the critical errors above before attempting deployment"
fi

echo ""
echo "For detailed deployment instructions, see: ./deploy.sh (no arguments)"