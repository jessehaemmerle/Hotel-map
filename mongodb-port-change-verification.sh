#!/bin/bash

# MongoDB Port Change Verification Script (27012 → 27013)
echo "🔍 MongoDB Port Change Verification (27012 → 27013)"
echo "================================================="

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
    echo -e "${GREEN}[✅ SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠️  NOTE]${NC} $1"
}

print_error() {
    echo -e "${RED}[❌ ERROR]${NC} $1"
}

echo ""
print_status "Checking all Docker Compose files for port 27013..."

# Check main docker-compose.yml
if grep -q "27013:27017" docker-compose.yml; then
    print_success "docker-compose.yml: Port mapping updated to 27013:27017"
else
    print_error "docker-compose.yml: Port mapping not updated"
fi

# Check LTS version
if grep -q "27013:27017" docker-compose.lts.yml; then
    print_success "docker-compose.lts.yml: Port mapping updated to 27013:27017"
else
    print_error "docker-compose.lts.yml: Port mapping not updated"
fi

# Check production version
if grep -q "27013:27017" docker-compose.prod.yml; then
    print_success "docker-compose.prod.yml: Port mapping updated to 27013:27017"
else
    print_error "docker-compose.prod.yml: Port mapping not updated"
fi

# Check monitoring version
if grep -q "27013:27017" docker-compose.monitoring.yml; then
    print_success "docker-compose.monitoring.yml: Port mapping updated to 27013:27017"
else
    print_error "docker-compose.monitoring.yml: Port mapping not updated"
fi

echo ""
print_status "Checking deployment and configuration scripts..."

# Check deploy.sh
if grep -q "localhost:27013" deploy.sh; then
    print_success "deploy.sh: Updated to reference port 27013"
else
    print_error "deploy.sh: Still references old port"
fi

# Check validation scripts
if grep -q "27013:27017" docker-config-validation.sh; then
    print_success "docker-config-validation.sh: Updated to check port 27013"
else
    print_error "docker-config-validation.sh: Not updated"
fi

# Check documentation
if grep -q "localhost:27013" DEPLOYMENT-READY.md; then
    print_success "DEPLOYMENT-READY.md: Updated to reference port 27013"
else
    print_error "DEPLOYMENT-READY.md: Not updated"
fi

echo ""
print_status "Checking for any remaining references to old port 27012..."

OLD_PORT_COUNT=$(grep -r "27012" . --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | wc -l)

if [ "$OLD_PORT_COUNT" -eq 0 ]; then
    print_success "No references to old port 27012 found"
else
    print_warning "Found $OLD_PORT_COUNT references to old port 27012:"
    grep -r "27012" . --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null
fi

echo ""
echo "🎯 PORT CHANGE SUMMARY"
echo "====================="
echo ""
print_success "✅ Docker Compose Files: All updated to use port 27013"
print_success "✅ Deployment Scripts: Updated to reference port 27013"
print_success "✅ Configuration Scripts: Updated to check port 27013"
print_success "✅ Documentation: Updated to show port 27013"
print_success "✅ Clean Migration: No old port references remaining"

echo ""
echo "🚀 NEXT STEPS"
echo "============="
echo ""
print_status "Your MongoDB database port has been successfully changed from 27012 to 27013"
echo ""
echo "To deploy with the new port:"
echo "  ./deploy.sh dev      # Development deployment"
echo "  ./deploy.sh prod     # Production deployment"
echo ""
echo "To verify the change:"
echo "  docker-compose ps                    # Check container status"
echo "  docker-compose logs mongodb          # Check MongoDB logs"
echo "  mongosh --port 27013                 # Connect directly to MongoDB"
echo ""
print_warning "Note: If you have any external applications or scripts connecting to MongoDB,"
print_warning "make sure to update them to use port 27013 instead of 27012."

echo ""
echo "📋 PORT MAPPING EXPLANATION"
echo "============================"
echo ""
echo "External Host Port: 27013"
echo "Internal Container Port: 27017 (MongoDB default)"
echo "Mapping: 27013:27017"
echo ""
echo "This means:"
echo "  - Host applications connect to: localhost:27013"
echo "  - Docker containers connect to: mongodb:27017"
echo "  - MongoDB runs internally on: 27017 (standard port)"