#!/bin/bash

echo "🐳 Testing Backend Docker Build Configuration"
echo "============================================="

# Check if all required files exist for Docker build
echo "📁 Checking backend files..."

required_backend_files=(
    "backend/requirements.txt"
    "backend/server.py"
    "Dockerfile.backend"
)

all_files_exist=true
for file in "${required_backend_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✅ $file"
    else
        echo "❌ $file (missing)"
        all_files_exist=false
    fi
done

# Check Dockerfile content
echo ""
echo "🔍 Checking Dockerfile.backend content..."
if grep -q "COPY backend/.env.docker .env" Dockerfile.backend; then
    echo "❌ Found problematic .env.docker copy command"
    echo "   This line should be removed for Docker builds"
else
    echo "✅ No problematic .env.docker copy command found"
fi

# Check environment variables in docker-compose.yml
echo ""
echo "🔧 Checking docker-compose.yml environment variables..."
if grep -q "MONGO_URL=mongodb://mongodb:27017" docker-compose.yml; then
    echo "✅ MONGO_URL configured for Docker"
else
    echo "❌ MONGO_URL not configured for Docker"
fi

if grep -q "JWT_SECRET=" docker-compose.yml; then
    echo "✅ JWT_SECRET configured"
else
    echo "❌ JWT_SECRET not configured"
fi

if grep -q "MAPBOX_ACCESS_TOKEN=" docker-compose.yml; then
    echo "✅ MAPBOX_ACCESS_TOKEN configured"
else
    echo "❌ MAPBOX_ACCESS_TOKEN not configured"
fi

# Check .env file for docker-compose
echo ""
echo "📋 Checking .env file for docker-compose..."
if [[ -f ".env" ]]; then
    if grep -q "MAPBOX_ACCESS_TOKEN=pk\." .env; then
        echo "✅ Mapbox token in .env file"
    else
        echo "⚠️  Mapbox token needs to be set in .env"
    fi
    
    if grep -q "JWT_SECRET=" .env; then
        echo "✅ JWT secret in .env file"
    else
        echo "⚠️  JWT secret needs to be set in .env"
    fi
else
    echo "❌ .env file missing for docker-compose"
fi

echo ""
echo "📋 Summary:"
if [[ "$all_files_exist" == true ]]; then
    echo "✅ All required files are present"
    echo "✅ Docker backend configuration should build successfully!"
    echo ""
    echo "🚀 To build and run:"
    echo "   docker compose build backend"
    echo "   docker compose up backend -d"
else
    echo "❌ Some required files are missing"
fi
