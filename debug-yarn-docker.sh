#!/bin/bash

echo "🔍 COMPREHENSIVE YARN LOCKFILE DEBUG"
echo "===================================="

echo "📋 Step 1: Check current package.json and yarn.lock"
cd frontend

echo "Package.json React version:"
grep -E '"react":|"react-dom":' package.json

echo ""
echo "Yarn.lock React versions:"
grep "react@\|react-dom@" yarn.lock | head -4

echo ""
echo "📋 Step 2: Test yarn install --frozen-lockfile (exactly like Docker)"
if yarn install --frozen-lockfile --silent; then
    echo "✅ yarn install --frozen-lockfile WORKS"
else
    echo "❌ yarn install --frozen-lockfile FAILS"
    echo ""
    echo "Trying to identify the issue..."
    yarn install --frozen-lockfile 2>&1 | head -20
    exit 1
fi

echo ""
echo "📋 Step 3: Simulate Docker build environment"
cd ..
mkdir -p /tmp/docker-test
cp frontend/package.json /tmp/docker-test/
cp frontend/yarn.lock /tmp/docker-test/
cd /tmp/docker-test

echo "Testing in clean environment like Docker would..."
if yarn install --frozen-lockfile --silent; then
    echo "✅ Clean environment install WORKS"
else
    echo "❌ Clean environment install FAILS"
    echo ""
    echo "Error output:"
    yarn install --frozen-lockfile 2>&1 | head -20
    cd /app
    rm -rf /tmp/docker-test
    exit 1
fi

cd /app
rm -rf /tmp/docker-test

echo ""
echo "📋 Step 4: Check for common issues"

# Check Node version
echo "Node version: $(node --version)"
echo "Yarn version: $(yarn --version)"

# Check for any conflicts
cd frontend
echo ""
echo "Checking for dependency conflicts..."
if yarn check --silent; then
    echo "✅ No dependency conflicts found"
else
    echo "⚠️  Dependency conflicts detected:"
    yarn check 2>&1 | head -10
fi

echo ""
echo "🎯 FINAL RESULT:"
echo "Docker build should work successfully!"
echo ""
echo "If Docker build still fails, the issue might be:"
echo "1. Different Node/Yarn version in Docker container"
echo "2. Network timeout in Docker build"
echo "3. Docker cache issues"
echo ""
echo "Try: docker compose build --no-cache frontend"