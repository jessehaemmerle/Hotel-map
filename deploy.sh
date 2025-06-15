#!/bin/bash

# Hotel Mapping Application Deployment Script
set -e

echo "🏨 Hotel Mapping Application Deployment"
echo "======================================"

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
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check for .env file
if [[ ! -f .env ]]; then
    print_warning ".env file not found. Creating from .env.example..."
    cp .env.example .env
    print_warning "Please edit .env file with your configuration before running again."
    print_warning "Especially set your MAPBOX_ACCESS_TOKEN!"
    exit 1
fi

# Load environment variables
source .env

# Check required environment variables
if [[ -z "$MAPBOX_ACCESS_TOKEN" || "$MAPBOX_ACCESS_TOKEN" == "your_mapbox_token_here" ]]; then
    print_error "Please set your MAPBOX_ACCESS_TOKEN in the .env file"
    exit 1
fi

# Function to deploy development environment
deploy_dev() {
    print_status "Deploying development environment..."
    
    # Stop existing containers
    print_status "Stopping existing containers..."
    docker-compose down -v
    
    # Build and start services
    print_status "Building and starting services..."
    docker-compose up --build -d
    
    # Wait for services to be healthy
    print_status "Waiting for services to start..."
    sleep 30
    
    # Check service health
    check_health
    
    print_success "Development environment deployed successfully!"
    print_status "Access your application at:"
    print_status "  Frontend: http://localhost:3000"
    print_status "  Backend API: http://localhost:8001"
    print_status "  MongoDB: localhost:27017"
    print_status "  Using: Node.js 21 (latest)"
}

# Function to deploy development environment with LTS
deploy_dev_lts() {
    print_status "Deploying development environment with Node.js 20 LTS..."
    
    # Stop existing containers
    print_status "Stopping existing containers..."
    docker-compose -f docker-compose.lts.yml down -v
    
    # Build and start services
    print_status "Building and starting services..."
    docker-compose -f docker-compose.lts.yml up --build -d
    
    # Wait for services to be healthy
    print_status "Waiting for services to start..."
    sleep 30
    
    # Check service health
    check_health
    
    print_success "Development environment deployed successfully!"
    print_status "Access your application at:"
    print_status "  Frontend: http://localhost:3000"
    print_status "  Backend API: http://localhost:8001"
    print_status "  MongoDB: localhost:27017"
    print_status "  Using: Node.js 20 LTS (stable)"
}

# Function to deploy production environment
deploy_prod() {
    print_status "Deploying production environment..."
    
    # Stop existing containers
    print_status "Stopping existing containers..."
    docker-compose -f docker-compose.prod.yml down -v
    
    # Build and start services
    print_status "Building and starting services..."
    docker-compose -f docker-compose.prod.yml up --build -d
    
    # Wait for services to be healthy
    print_status "Waiting for services to start..."
    sleep 45
    
    # Check service health
    check_health_prod
    
    print_success "Production environment deployed successfully!"
    print_status "Access your application at:"
    print_status "  Application: http://localhost (redirects to HTTPS)"
    print_status "  HTTPS: https://localhost (configure SSL certificates)"
}

# Function to check service health
check_health() {
    print_status "Checking service health..."
    
    # Check MongoDB
    if docker-compose exec -T mongodb mongosh --eval "db.adminCommand('ping')" --quiet; then
        print_success "MongoDB is healthy"
    else
        print_error "MongoDB is not healthy"
    fi
    
    # Check Backend
    if curl -f http://localhost:8001/api/hotels >/dev/null 2>&1; then
        print_success "Backend is healthy"
    else
        print_error "Backend is not healthy"
    fi
    
    # Check Frontend
    if curl -f http://localhost:3000 >/dev/null 2>&1; then
        print_success "Frontend is healthy"
    else
        print_error "Frontend is not healthy"
    fi
}

# Function to check production service health
check_health_prod() {
    print_status "Checking production service health..."
    
    # Check if containers are running
    if docker-compose -f docker-compose.prod.yml ps | grep -q "Up"; then
        print_success "All services are running"
    else
        print_error "Some services are not running"
        docker-compose -f docker-compose.prod.yml ps
    fi
}

# Function to show logs
show_logs() {
    echo "Which service logs would you like to see?"
    echo "1) All services"
    echo "2) Backend"
    echo "3) Frontend" 
    echo "4) MongoDB"
    read -p "Enter choice [1-4]: " choice
    
    case $choice in
        1) docker-compose logs -f ;;
        2) docker-compose logs -f backend ;;
        3) docker-compose logs -f frontend ;;
        4) docker-compose logs -f mongodb ;;
        *) print_error "Invalid choice" ;;
    esac
}

# Function to stop services
stop_services() {
    print_status "Stopping all services..."
    docker-compose down
    docker-compose -f docker-compose.lts.yml down
    docker-compose -f docker-compose.prod.yml down
    print_success "All services stopped"
}

# Function to clean up
cleanup() {
    print_warning "This will remove all containers, images, and volumes. Are you sure? (y/N)"
    read -p "" confirm
    if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
        print_status "Cleaning up..."
        docker-compose down -v --rmi all
        docker-compose -f docker-compose.lts.yml down -v --rmi all
        docker-compose -f docker-compose.prod.yml down -v --rmi all
        docker system prune -f
        print_success "Cleanup complete"
    fi
}

# Main menu
case "${1:-}" in
    "dev")
        deploy_dev
        ;;
    "dev-lts")
        deploy_dev_lts
        ;;
    "prod")
        deploy_prod
        ;;
    "logs")
        show_logs
        ;;
    "stop")
        stop_services
        ;;
    "cleanup")
        cleanup
        ;;
    "health")
        check_health
        ;;
    *)
        echo "Hotel Mapping Application Deployment Script"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  dev      Deploy development environment (Node.js 21 latest)"
        echo "  dev-lts  Deploy development environment (Node.js 20 LTS)" 
        echo "  prod     Deploy production environment"
        echo "  logs     Show service logs"
        echo "  stop     Stop all services"
        echo "  health   Check service health"
        echo "  cleanup  Remove all containers and images"
        echo ""
        echo "Examples:"
        echo "  $0 dev      # Deploy with Node.js 21 (latest)"
        echo "  $0 dev-lts  # Deploy with Node.js 20 LTS (stable)"
        echo "  $0 prod     # Deploy for production"
        echo "  $0 logs     # View logs"
        ;;
esac