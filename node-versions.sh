#!/bin/bash

# Node.js Version Information for Hotel Mapping Application
echo "🏨 Hotel Mapping Application - Node.js Version Information"
echo "========================================================"

echo ""
echo "📦 Available Docker Configurations:"
echo ""

echo "1. 🚀 Latest (Node.js 21)"
echo "   - File: Dockerfile.frontend"
echo "   - Compose: docker-compose.yml"
echo "   - Command: ./deploy.sh dev"
echo "   - Features: Latest Node.js features and performance"
echo ""

echo "2. 🛡️  LTS Stable (Node.js 20)"
echo "   - File: Dockerfile.frontend.lts"
echo "   - Compose: docker-compose.lts.yml"
echo "   - Command: ./deploy.sh dev-lts"
echo "   - Features: Long-term support, maximum stability"
echo ""

echo "📋 Current Configuration:"
echo ""

# Check which versions are specified
echo "Main Dockerfile (latest):"
grep "FROM node:" Dockerfile.frontend
echo ""

echo "LTS Dockerfile (stable):"
grep "FROM node:" Dockerfile.frontend.lts
echo ""

echo "Package.json engines requirement:"
grep -A 3 "engines" frontend/package.json
echo ""

echo "🚀 Deploy Commands:"
echo "  Latest:  ./deploy.sh dev"
echo "  LTS:     ./deploy.sh dev-lts"
echo "  Production: ./deploy.sh prod"
echo ""

echo "🔍 Check Node.js versions available:"
echo "  docker run --rm node:21-alpine node --version"
echo "  docker run --rm node:20-alpine node --version"