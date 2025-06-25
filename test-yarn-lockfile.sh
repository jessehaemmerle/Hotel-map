#!/bin/bash

echo "🔧 YARN LOCKFILE ISSUE - VERIFICATION TEST"
echo "=========================================="

echo "📦 Checking package.json and yarn.lock compatibility..."

cd frontend

# Check if package.json and yarn.lock are compatible
echo "🔍 Testing yarn install with --frozen-lockfile..."
if yarn install --frozen-lockfile --silent 2>/dev/null; then
    echo "✅ yarn.lock is compatible with package.json"
else
    echo "❌ yarn.lock is NOT compatible with package.json"
    echo "   This would cause Docker build to fail"
    exit 1
fi

# Check React version
echo ""
echo "📋 Current React version:"
REACT_VERSION=$(yarn list react --depth=0 2>/dev/null | grep "react@" | sed 's/.*react@//' | sed 's/ .*//')
echo "   React: $REACT_VERSION"

REACT_DOM_VERSION=$(yarn list react-dom --depth=0 2>/dev/null | grep "react-dom@" | sed 's/.*react-dom@//' | sed 's/ .*//')
echo "   React DOM: $REACT_DOM_VERSION"

# Verify versions match expected (React 18.x)
if [[ $REACT_VERSION == 18.* && $REACT_DOM_VERSION == 18.* ]]; then
    echo "✅ React 18 successfully installed"
else
    echo "❌ React version mismatch or not React 18"
    exit 1
fi

cd ..

echo ""
echo "🐳 Docker Build Readiness Check:"

# Check Dockerfile.frontend for frozen-lockfile
if grep -q "yarn install --frozen-lockfile" Dockerfile.frontend; then
    echo "✅ Dockerfile uses --frozen-lockfile (good for reproducible builds)"
else
    echo "⚠️  Dockerfile doesn't use --frozen-lockfile"
fi

# Check that both package.json and yarn.lock exist
if [[ -f "frontend/package.json" && -f "frontend/yarn.lock" ]]; then
    echo "✅ Both package.json and yarn.lock exist"
else
    echo "❌ Missing package.json or yarn.lock"
    exit 1
fi

echo ""
echo "🎉 RESULT: Docker build should now work successfully!"
echo ""
echo "🚀 You can now run:"
echo "   docker compose build frontend"
echo "   docker compose build"
echo "   docker compose up --build -d"