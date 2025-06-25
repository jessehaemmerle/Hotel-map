#!/bin/bash

# Validate Docker setup for Hotel Mapping Application
echo "🏨 Validating Docker Setup for Hotel Mapping Application"
echo "======================================================="

# Check if all required files exist
echo "📁 Checking required files..."

required_files=(
    "docker-compose.yml"
    "docker-compose.prod.yml"
    "Dockerfile.backend"
    "Dockerfile.frontend"
    "nginx.conf"
    "nginx-prod.conf"
    "mongo-init.js"
    ".env"
    "deploy.sh"
)

all_files_exist=true
for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✅ $file"
    else
        echo "❌ $file (missing)"
        all_files_exist=false
    fi
done

# Check .env file content
echo ""
echo "🔧 Checking environment configuration..."
if [[ -f ".env" ]]; then
    if grep -q "MAPBOX_ACCESS_TOKEN=pk\." .env; then
        echo "✅ Mapbox token configured"
    else
        echo "⚠️  Mapbox token needs to be set"
    fi
    
    if grep -q "JWT_SECRET=.*" .env; then
        echo "✅ JWT secret configured"
    else
        echo "⚠️  JWT secret needs to be set"
    fi
else
    echo "❌ .env file missing"
fi

# Check Docker files syntax
echo ""
echo "🐳 Validating Docker configurations..."

# Basic YAML syntax check for docker-compose files
if command -v python3 &> /dev/null; then
    python3 -c "
import yaml
try:
    with open('docker-compose.yml') as f:
        yaml.safe_load(f)
    print('✅ docker-compose.yml syntax valid')
except Exception as e:
    print(f'❌ docker-compose.yml syntax error: {e}')

try:
    with open('docker-compose.prod.yml') as f:
        yaml.safe_load(f)
    print('✅ docker-compose.prod.yml syntax valid')
except Exception as e:
    print(f'❌ docker-compose.prod.yml syntax error: {e}')
" 2>/dev/null || echo "⚠️  Python not available for YAML validation"
fi

# Check if deploy script is executable
if [[ -x "deploy.sh" ]]; then
    echo "✅ deploy.sh is executable"
else
    echo "❌ deploy.sh is not executable (run: chmod +x deploy.sh)"
fi

echo ""
echo "📋 Summary:"
if [[ "$all_files_exist" == true ]]; then
    echo "✅ All Docker files are present"
    echo "✅ Your application is ready for Docker deployment!"
    echo ""
    echo "🚀 To deploy:"
    echo "   Development: ./deploy.sh dev"
    echo "   Production:  ./deploy.sh prod"
    echo ""
    echo "📖 For detailed instructions, see README-Docker.md"
else
    echo "❌ Some required files are missing"
    echo "Please ensure all Docker configuration files are present"
fi

echo ""
echo "🔗 Access URLs after deployment:"
echo "   Frontend:    http://localhost:7070"
echo "   Backend API: http://localhost:8001"
echo "   MongoDB:     localhost:27013"
echo "   API Docs:    http://localhost:8001/docs"