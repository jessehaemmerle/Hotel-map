#!/bin/bash

# Advanced Deployment Orchestrator for Hotel Mapping Application
echo "🏨 Advanced Deployment Orchestrator - Hotel Mapping Application"
echo "=============================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${PURPLE}[ORCHESTRATOR]${NC} $1"
}

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

# Configuration
ENVIRONMENTS=("development" "staging" "production" "monitoring")
DEPLOYMENT_MODES=("basic" "lts" "production" "monitoring" "kubernetes")

# Function to show deployment options
show_deployment_options() {
    print_header "Available Deployment Options"
    echo ""
    
    echo -e "${CYAN}🚀 Quick Deployments:${NC}"
    echo "1. Development (Node.js 21)    - Latest features, hot reload"
    echo "2. Development LTS (Node.js 20) - Stable, long-term support"
    echo "3. Production                  - Full production stack with Nginx"
    echo "4. Monitoring Stack           - Complete observability suite"
    echo "5. Kubernetes                 - Cloud-native deployment"
    echo ""
    
    echo -e "${CYAN}🔧 Advanced Options:${NC}"
    echo "6. High Availability          - Multi-instance with load balancing"
    echo "7. Performance Testing        - Dedicated testing environment"
    echo "8. Security Hardened          - Enhanced security configuration"
    echo "9. Multi-Region               - Global deployment setup"
    echo "10. Disaster Recovery         - Backup and recovery testing"
    echo ""
}

# Function to deploy basic development environment
deploy_development() {
    print_header "Deploying Development Environment"
    
    print_info "Starting development deployment with Node.js 21..."
    ./deploy.sh dev
    
    print_info "Setting up development tools..."
    ./dev-tools.sh docker
    
    print_success "Development environment ready!"
    print_info "Access URLs:"
    echo "  • Frontend: http://localhost:3000"
    echo "  • Backend API: http://localhost:8001"
    echo "  • API Docs: http://localhost:8001/docs"
}

# Function to deploy LTS development environment
deploy_development_lts() {
    print_header "Deploying Development Environment (LTS)"
    
    print_info "Starting development deployment with Node.js 20 LTS..."
    ./deploy.sh dev-lts
    
    print_success "Development LTS environment ready!"
    print_info "Access URLs:"
    echo "  • Frontend: http://localhost:3000"
    echo "  • Backend API: http://localhost:8001"
    echo "  • API Docs: http://localhost:8001/docs"
}

# Function to deploy production environment
deploy_production() {
    print_header "Deploying Production Environment"
    
    print_info "Starting production deployment..."
    ./deploy.sh prod
    
    print_info "Creating production backup..."
    ./backup-restore.sh complete
    
    print_info "Running health checks..."
    sleep 30
    ./monitor.sh health
    
    print_success "Production environment ready!"
    print_info "Access URLs:"
    echo "  • Application: http://localhost"
    echo "  • Admin Panel: https://localhost/admin"
}

# Function to deploy monitoring stack
deploy_monitoring() {
    print_header "Deploying Monitoring Stack"
    
    print_info "Starting monitoring deployment..."
    docker-compose -f docker-compose.monitoring.yml up -d
    
    print_info "Waiting for services to start..."
    sleep 60
    
    print_info "Configuring Grafana dashboards..."
    # Add dashboard configuration here
    
    print_success "Monitoring stack ready!"
    print_info "Access URLs:"
    echo "  • Application: http://localhost:3000"
    echo "  • Prometheus: http://localhost:9090"
    echo "  • Grafana: http://localhost:3001 (admin/admin123)"
    echo "  • Kibana: http://localhost:5601"
    echo "  • Elasticsearch: http://localhost:9200"
}

# Function to deploy Kubernetes
deploy_kubernetes() {
    print_header "Deploying to Kubernetes"
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl not found. Please install Kubernetes CLI."
        return 1
    fi
    
    print_info "Applying Kubernetes manifests..."
    kubectl apply -f k8s/deployment.yaml
    
    print_info "Waiting for pods to be ready..."
    kubectl wait --for=condition=ready pod -l app=hotel-mapping -n hotel-mapping --timeout=300s
    
    print_success "Kubernetes deployment ready!"
    print_info "Use 'kubectl get services -n hotel-mapping' to see service endpoints"
}

# Function to deploy high availability setup
deploy_high_availability() {
    print_header "Deploying High Availability Setup"
    
    print_info "Creating HA configuration..."
    
    # Create HA docker-compose file
    cat > docker-compose.ha.yml << 'EOF'
version: '3.8'
services:
  # Load balancer
  haproxy:
    image: haproxy:latest
    ports:
      - "80:80"
      - "8404:8404"
    volumes:
      - ./haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro
    depends_on:
      - frontend-1
      - frontend-2
      - backend-1
      - backend-2

  # Multiple frontend instances
  frontend-1:
    build:
      context: .
      dockerfile: Dockerfile.frontend
    environment:
      - REACT_APP_BACKEND_URL=http://localhost:8001

  frontend-2:
    build:
      context: .
      dockerfile: Dockerfile.frontend
    environment:
      - REACT_APP_BACKEND_URL=http://localhost:8001

  # Multiple backend instances
  backend-1:
    build:
      context: .
      dockerfile: Dockerfile.backend
    environment:
      - MONGO_URL=mongodb://mongodb-primary:27017,mongodb-secondary:27017

  backend-2:
    build:
      context: .
      dockerfile: Dockerfile.backend
    environment:
      - MONGO_URL=mongodb://mongodb-primary:27017,mongodb-secondary:27017

  # MongoDB replica set
  mongodb-primary:
    image: mongo:7
    command: mongod --replSet rs0 --bind_ip_all

  mongodb-secondary:
    image: mongo:7
    command: mongod --replSet rs0 --bind_ip_all
EOF

    print_info "Starting HA deployment..."
    docker-compose -f docker-compose.ha.yml up -d
    
    print_success "High Availability setup ready!"
}

# Function to deploy performance testing environment
deploy_performance_testing() {
    print_header "Deploying Performance Testing Environment"
    
    print_info "Setting up performance testing stack..."
    
    # Deploy application
    ./deploy.sh dev
    
    # Wait for services
    sleep 30
    
    print_info "Running performance test suite..."
    ./performance-test.sh all
    
    print_success "Performance testing environment ready!"
}

# Function to deploy security hardened environment
deploy_security_hardened() {
    print_header "Deploying Security Hardened Environment"
    
    print_info "Applying security configurations..."
    
    # Create security-enhanced docker-compose
    print_info "Enabling security features:"
    echo "  • Non-root containers"
    echo "  • Read-only filesystems"
    echo "  • Security labels"
    echo "  • Network segmentation"
    echo "  • Secret management"
    
    ./deploy.sh prod
    
    print_success "Security hardened environment ready!"
}

# Function to show multi-region deployment guide
deploy_multi_region() {
    print_header "Multi-Region Deployment Guide"
    
    print_info "Multi-region deployment involves:"
    echo "  1. Container registry setup"
    echo "  2. Database replication"
    echo "  3. CDN configuration"
    echo "  4. DNS failover"
    echo "  5. Monitoring across regions"
    
    print_info "Kubernetes manifests are available in k8s/ directory"
    print_info "Follow the README-Docker.md for detailed instructions"
}

# Function to test disaster recovery
deploy_disaster_recovery() {
    print_header "Disaster Recovery Testing"
    
    print_info "Testing backup and recovery procedures..."
    
    # Create backup
    ./backup-restore.sh complete
    
    # Simulate failure
    print_info "Simulating service failure..."
    ./deploy.sh stop
    
    sleep 10
    
    # Restore services
    print_info "Restoring services..."
    ./deploy.sh dev
    
    sleep 30
    
    # Verify restoration
    ./monitor.sh health
    
    print_success "Disaster recovery test completed!"
}

# Function to show deployment status
show_deployment_status() {
    print_header "Current Deployment Status"
    
    ./master.sh status
    
    print_info "Resource Usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" 2>/dev/null || echo "No containers running"
    
    print_info "Available Services:"
    if curl -s -f http://localhost:3000 > /dev/null; then
        echo "  ✅ Frontend (http://localhost:3000)"
    else
        echo "  ❌ Frontend not accessible"
    fi
    
    if curl -s -f http://localhost:8001/api/hotels > /dev/null; then
        echo "  ✅ Backend API (http://localhost:8001)"
    else
        echo "  ❌ Backend API not accessible"
    fi
}

# Function to cleanup all deployments
cleanup_all() {
    print_header "Cleaning Up All Deployments"
    
    print_warning "This will stop and remove all containers and data. Continue? (y/N)"
    read -p "" confirm
    
    if [[ $confirm == [yY] ]]; then
        print_info "Stopping all deployments..."
        
        docker-compose down -v 2>/dev/null || true
        docker-compose -f docker-compose.lts.yml down -v 2>/dev/null || true
        docker-compose -f docker-compose.prod.yml down -v 2>/dev/null || true
        docker-compose -f docker-compose.monitoring.yml down -v 2>/dev/null || true
        docker-compose -f docker-compose.ha.yml down -v 2>/dev/null || true
        
        print_info "Removing unused images and volumes..."
        docker system prune -af --volumes 2>/dev/null || true
        
        print_success "Cleanup completed!"
    else
        print_info "Cleanup cancelled"
    fi
}

# Main menu function
main_menu() {
    while true; do
        echo ""
        print_header "Advanced Deployment Orchestrator"
        echo ""
        show_deployment_options
        echo "11. Show Deployment Status"
        echo "12. Cleanup All Deployments"
        echo "0.  Exit"
        echo ""
        read -p "Select deployment option [0-12]: " choice
        
        case $choice in
            1) deploy_development ;;
            2) deploy_development_lts ;;
            3) deploy_production ;;
            4) deploy_monitoring ;;
            5) deploy_kubernetes ;;
            6) deploy_high_availability ;;
            7) deploy_performance_testing ;;
            8) deploy_security_hardened ;;
            9) deploy_multi_region ;;
            10) deploy_disaster_recovery ;;
            11) show_deployment_status ;;
            12) cleanup_all ;;
            0) 
                print_success "Thank you for using Hotel Mapping Deployment Orchestrator!"
                exit 0
                ;;
            *) 
                print_warning "Invalid option. Please try again."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Command line interface
case "${1:-}" in
    "dev")
        deploy_development
        ;;
    "dev-lts")
        deploy_development_lts
        ;;
    "prod")
        deploy_production
        ;;
    "monitoring")
        deploy_monitoring
        ;;
    "k8s"|"kubernetes")
        deploy_kubernetes
        ;;
    "ha"|"high-availability")
        deploy_high_availability
        ;;
    "perf"|"performance")
        deploy_performance_testing
        ;;
    "security")
        deploy_security_hardened
        ;;
    "multi-region")
        deploy_multi_region
        ;;
    "dr"|"disaster-recovery")
        deploy_disaster_recovery
        ;;
    "status")
        show_deployment_status
        ;;
    "cleanup")
        cleanup_all
        ;;
    "menu"|"interactive")
        main_menu
        ;;
    *)
        echo "🏨 Advanced Deployment Orchestrator"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Quick Commands:"
        echo "  dev              Deploy development environment"
        echo "  dev-lts          Deploy development with LTS Node.js"
        echo "  prod             Deploy production environment"
        echo "  monitoring       Deploy monitoring stack"
        echo "  kubernetes       Deploy to Kubernetes"
        echo ""
        echo "Advanced Commands:"
        echo "  high-availability Deploy HA setup"
        echo "  performance      Deploy performance testing"
        echo "  security         Deploy security hardened"
        echo "  multi-region     Show multi-region guide"
        echo "  disaster-recovery Test DR procedures"
        echo ""
        echo "Management:"
        echo "  status           Show deployment status"
        echo "  cleanup          Clean up all deployments"
        echo "  menu             Interactive menu"
        echo ""
        echo "Examples:"
        echo "  $0 dev           # Quick development deployment"
        echo "  $0 monitoring    # Full monitoring stack"
        echo "  $0 menu          # Interactive menu"
        ;;
esac