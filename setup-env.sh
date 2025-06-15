#!/bin/bash

# Environment Setup Script for Hotel Mapping Application
echo "🏨 Setting up environment files for Hotel Mapping Application"
echo "==========================================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Your Mapbox token
MAPBOX_TOKEN="pk.eyJ1IjoiamVzbWFudGhlcmVhbCIsImEiOiJjbGlvNm44OGUwcDMyM3JwbnR5eXFlYXVuIn0.IkkPG8K1H5MtkAaQI9sitQ"
JWT_SECRET="hotel-mapping-super-secret-jwt-key-change-in-production-2024"

echo -e "${BLUE}[INFO]${NC} Creating root .env file for Docker..."

# Create root .env file for Docker
cat > .env << EOF
# Environment variables for Hotel Mapping Application - Docker Deployment

# Mapbox Configuration (Required)
MAPBOX_ACCESS_TOKEN=${MAPBOX_TOKEN}

# Backend Configuration for Docker
JWT_SECRET=${JWT_SECRET}
REACT_APP_BACKEND_URL=http://localhost:8001

# Database Configuration for Docker
MONGO_URL=mongodb://mongodb:27017
DB_NAME=hotel_mapping

# Production Configuration (for docker-compose.prod.yml)
MONGO_ROOT_USER=admin
MONGO_ROOT_PASSWORD=securepassword123

# Development/Production flags
NODE_ENV=development
PYTHONPATH=/app
EOF

echo -e "${GREEN}[SUCCESS]${NC} Created root .env file"

echo -e "${BLUE}[INFO]${NC} Creating frontend .env.docker file..."

# Create frontend .env.docker file
cat > frontend/.env.docker << EOF
# Frontend environment variables for Docker deployment
REACT_APP_BACKEND_URL=http://localhost:8001
REACT_APP_MAPBOX_TOKEN=${MAPBOX_TOKEN}
WDS_SOCKET_PORT=443
EOF

echo -e "${GREEN}[SUCCESS]${NC} Created frontend/.env.docker file"

echo -e "${BLUE}[INFO]${NC} Creating backend .env.docker file..."

# Create backend .env.docker file
cat > backend/.env.docker << EOF
# Backend environment variables for Docker deployment
MONGO_URL=mongodb://mongodb:27017
DB_NAME=hotel_mapping
MAPBOX_ACCESS_TOKEN=${MAPBOX_TOKEN}
JWT_SECRET=${JWT_SECRET}
EOF

echo -e "${GREEN}[SUCCESS]${NC} Created backend/.env.docker file"

echo -e "${BLUE}[INFO]${NC} Updating current development .env files..."

# Update current frontend .env for development
cat > frontend/.env << EOF
WDS_SOCKET_PORT=443
REACT_APP_BACKEND_URL=https://e9b4dd7d-b3a8-44d3-b08e-bd05832659cc.preview.emergentagent.com
REACT_APP_MAPBOX_TOKEN=${MAPBOX_TOKEN}
EOF

# Update current backend .env for development
cat > backend/.env << EOF
MONGO_URL="mongodb://localhost:27017"
DB_NAME="hotel_mapping"
MAPBOX_ACCESS_TOKEN="${MAPBOX_TOKEN}"
JWT_SECRET="${JWT_SECRET}"
EOF

echo -e "${GREEN}[SUCCESS]${NC} Updated development .env files"

echo ""
echo -e "${GREEN}✅ Environment setup complete!${NC}"
echo ""
echo "📁 Created files:"
echo "  ✅ .env (root - for Docker)"
echo "  ✅ frontend/.env (development)"
echo "  ✅ frontend/.env.docker (Docker)"
echo "  ✅ backend/.env (development)"
echo "  ✅ backend/.env.docker (Docker)"
echo ""
echo "🚀 You can now:"
echo "  • Continue development: Current environment works as before"
echo "  • Deploy with Docker: ./deploy.sh dev"
echo "  • Deploy production: ./deploy.sh prod"
echo ""
echo -e "${YELLOW}[NOTE]${NC} Your Mapbox token is configured in all files"