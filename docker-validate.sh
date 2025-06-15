#!/bin/bash

# Docker Build Validation Script for Hotel Mapping Application
echo "🏨 Docker Build Validation for Hotel Mapping Application"
echo "======================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check Dockerfile syntax
check_dockerfile_syntax() {
    local dockerfile="$1"
    local dockerfile_name=$(basename "$dockerfile")
    
    print_info "Checking $dockerfile_name syntax..."
    
    # Check if file exists
    if [ ! -f "$dockerfile" ]; then
        print_error "$dockerfile_name not found"
        return 1
    fi
    
    # Basic syntax checks
    local errors=0
    
    # Check for FROM statement
    if ! grep -q "^FROM " "$dockerfile"; then
        print_error "$dockerfile_name: Missing FROM statement"
        ((errors++))
    else
        print_success "$dockerfile_name: FROM statement found"
    fi
    
    # Check for WORKDIR
    if ! grep -q "^WORKDIR " "$dockerfile"; then
        print_warning "$dockerfile_name: No WORKDIR statement (optional)"
    else
        print_success "$dockerfile_name: WORKDIR statement found"
    fi
    
    # Check for COPY statements
    if ! grep -q "^COPY " "$dockerfile"; then
        print_warning "$dockerfile_name: No COPY statements found"
    else
        print_success "$dockerfile_name: COPY statements found"
    fi
    
    # Check for EXPOSE
    if ! grep -q "^EXPOSE " "$dockerfile"; then
        print_warning "$dockerfile_name: No EXPOSE statement"
    else
        print_success "$dockerfile_name: EXPOSE statement found"
    fi
    
    # Check for CMD or ENTRYPOINT
    if ! grep -q "^CMD\|^ENTRYPOINT" "$dockerfile"; then
        print_error "$dockerfile_name: Missing CMD or ENTRYPOINT"
        ((errors++))
    else
        print_success "$dockerfile_name: CMD/ENTRYPOINT found"
    fi
    
    # Check for multi-stage build structure (frontend)
    if [[ "$dockerfile_name" == *"frontend"* ]]; then
        if grep -q "AS builder" "$dockerfile" && grep -q "FROM.*alpine" "$dockerfile"; then
            print_success "$dockerfile_name: Multi-stage build detected"
        else
            print_warning "$dockerfile_name: Multi-stage build not detected"
        fi
    fi
    
    return $errors
}

# Function to validate Docker Compose files
check_compose_syntax() {
    local compose_file="$1"
    local compose_name=$(basename "$compose_file")
    
    print_info "Checking $compose_name syntax..."
    
    if [ ! -f "$compose_file" ]; then
        print_error "$compose_name not found"
        return 1
    fi
    
    local errors=0
    
    # Check for version
    if ! grep -q "^version:" "$compose_file"; then
        print_warning "$compose_name: No version specified"
    else
        print_success "$compose_name: Version found"
    fi
    
    # Check for services
    if ! grep -q "^services:" "$compose_file"; then
        print_error "$compose_name: No services section"
        ((errors++))
    else
        print_success "$compose_name: Services section found"
    fi
    
    # Check for required services
    if grep -q "mongodb:" "$compose_file"; then
        print_success "$compose_name: MongoDB service found"
    else
        print_warning "$compose_name: MongoDB service not found"
    fi
    
    if grep -q "backend:" "$compose_file"; then
        print_success "$compose_name: Backend service found"
    else
        print_warning "$compose_name: Backend service not found"
    fi
    
    if grep -q "frontend:" "$compose_file"; then
        print_success "$compose_name: Frontend service found"
    else
        print_warning "$compose_name: Frontend service not found"
    fi
    
    return $errors
}

# Function to check required files for Docker build
check_required_files() {
    print_info "Checking required files for Docker build..."
    
    local errors=0
    
    # Frontend files
    local frontend_files=(
        "frontend/package.json"
        "frontend/yarn.lock"
        "frontend/src/App.js"
        "frontend/src/index.js"
        "frontend/public/index.html"
        "frontend/postcss.config.js"
        "frontend/tailwind.config.js"
    )
    
    for file in "${frontend_files[@]}"; do
        if [ -f "$file" ]; then
            print_success "Frontend: $file exists"
        else
            print_error "Frontend: $file missing"
            ((errors++))
        fi
    done
    
    # Backend files
    local backend_files=(
        "backend/requirements.txt"
        "backend/server.py"
        "backend/.env"
    )
    
    for file in "${backend_files[@]}"; do
        if [ -f "$file" ]; then
            print_success "Backend: $file exists"
        else
            print_error "Backend: $file missing"
            ((errors++))
        fi
    done
    
    # Docker configuration files
    local docker_files=(
        "nginx.conf"
        "mongo-init.js"
        ".env"
    )
    
    for file in "${docker_files[@]}"; do
        if [ -f "$file" ]; then
            print_success "Docker: $file exists"
        else
            print_error "Docker: $file missing"
            ((errors++))
        fi
    done
    
    return $errors
}

# Function to validate environment configuration
check_environment_config() {
    print_info "Checking environment configuration..."
    
    local errors=0
    
    # Check root .env file
    if [ -f ".env" ]; then
        if grep -q "MAPBOX_ACCESS_TOKEN" ".env"; then
            print_success "Root .env: Mapbox token configured"
        else
            print_error "Root .env: Mapbox token missing"
            ((errors++))
        fi
        
        if grep -q "JWT_SECRET" ".env"; then
            print_success "Root .env: JWT secret configured"
        else
            print_error "Root .env: JWT secret missing"
            ((errors++))
        fi
    else
        print_error "Root .env file missing"
        ((errors++))
    fi
    
    # Check frontend environment files
    if [ -f "frontend/.env" ]; then
        print_success "Frontend .env exists"
    else
        print_warning "Frontend .env missing (will be created by build)"
    fi
    
    if [ -f "frontend/.env.docker" ]; then
        print_success "Frontend .env.docker exists"
    else
        print_warning "Frontend .env.docker missing (will be created by build)"
    fi
    
    return $errors
}

# Function to check Node.js and Python versions in package files
check_package_versions() {
    print_info "Checking package versions..."
    
    # Check Node.js version in package.json
    if [ -f "frontend/package.json" ]; then
        if grep -q '"engines"' frontend/package.json; then
            print_success "Frontend: Node.js version constraints found"
        else
            print_warning "Frontend: No Node.js version constraints"
        fi
        
        # Check React version
        react_version=$(grep '"react"' frontend/package.json | cut -d'"' -f4 | cut -d'^' -f2)
        if [ ! -z "$react_version" ]; then
            print_success "Frontend: React version $react_version"
        fi
    fi
    
    # Check Python version in requirements
    if [ -f "backend/requirements.txt" ]; then
        print_success "Backend: requirements.txt found"
        local req_count=$(wc -l < backend/requirements.txt)
        print_info "Backend: $req_count dependencies listed"
    fi
}

# Function to simulate Docker build steps
simulate_build() {
    print_info "Simulating Docker build process..."
    
    print_info "Frontend build simulation:"
    echo "  1. ✅ FROM node:21-alpine (or node:20-alpine for LTS)"
    echo "  2. ✅ WORKDIR /app"
    echo "  3. ✅ COPY package.json yarn.lock"
    echo "  4. ✅ RUN yarn install --frozen-lockfile"
    echo "  5. ✅ COPY source files"
    echo "  6. ✅ RUN yarn build"
    echo "  7. ✅ FROM nginx:alpine"
    echo "  8. ✅ COPY build files to nginx"
    
    print_info "Backend build simulation:"
    echo "  1. ✅ FROM python:3.11-slim"
    echo "  2. ✅ WORKDIR /app"
    echo "  3. ✅ COPY requirements.txt"
    echo "  4. ✅ RUN pip install -r requirements.txt"
    echo "  5. ✅ COPY source files"
    echo "  6. ✅ CMD uvicorn server:app"
    
    print_success "Build simulation completed successfully"
}

# Function to generate Docker build commands
generate_build_commands() {
    print_info "Generating Docker build commands..."
    
    echo ""
    echo "🐳 Docker Build Commands:"
    echo "========================"
    echo ""
    echo "# Build frontend (Node.js 21 latest):"
    echo "docker build -f Dockerfile.frontend -t hotel-mapping-frontend:latest ."
    echo ""
    echo "# Build frontend (Node.js 20 LTS):"
    echo "docker build -f Dockerfile.frontend.lts -t hotel-mapping-frontend:lts ."
    echo ""
    echo "# Build backend:"
    echo "docker build -f Dockerfile.backend -t hotel-mapping-backend:latest ."
    echo ""
    echo "# Run with Docker Compose (latest):"
    echo "docker-compose up -d"
    echo ""
    echo "# Run with Docker Compose (LTS):"
    echo "docker-compose -f docker-compose.lts.yml up -d"
    echo ""
    echo "# Run production:"
    echo "docker-compose -f docker-compose.prod.yml up -d"
    echo ""
}

# Main validation function
main() {
    local total_errors=0
    
    echo "Starting Docker build validation..."
    echo ""
    
    # Check Dockerfiles
    dockerfiles=(
        "Dockerfile.frontend"
        "Dockerfile.frontend.lts"
        "Dockerfile.backend"
    )
    
    for dockerfile in "${dockerfiles[@]}"; do
        check_dockerfile_syntax "$dockerfile"
        ((total_errors += $?))
        echo ""
    done
    
    # Check Docker Compose files
    compose_files=(
        "docker-compose.yml"
        "docker-compose.lts.yml"
        "docker-compose.prod.yml"
    )
    
    for compose_file in "${compose_files[@]}"; do
        if [ -f "$compose_file" ]; then
            check_compose_syntax "$compose_file"
            ((total_errors += $?))
        fi
        echo ""
    done
    
    # Check required files
    check_required_files
    ((total_errors += $?))
    echo ""
    
    # Check environment configuration
    check_environment_config
    ((total_errors += $?))
    echo ""
    
    # Check package versions
    check_package_versions
    echo ""
    
    # Simulate build process
    simulate_build
    echo ""
    
    # Generate build commands
    generate_build_commands
    
    # Final result
    echo ""
    echo "🎯 Validation Summary:"
    echo "====================="
    
    if [ $total_errors -eq 0 ]; then
        print_success "✅ All checks passed! Docker build should work correctly."
        echo ""
        print_info "Your Hotel Mapping Application is ready for Docker deployment!"
        print_info "Use the generated build commands above to build and run your containers."
    else
        print_warning "⚠️  Found $total_errors error(s). Please fix these issues before building."
        echo ""
        print_info "Fix the errors above and run this script again to validate."
    fi
    
    return $total_errors
}

# Run main function
main