#!/bin/bash

# Enhanced monitoring script for Hotel Mapping Application
echo "🏨 Hotel Mapping Application - System Monitor"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${PURPLE}[MONITOR]${NC} $1"
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

# Function to check Docker containers
check_containers() {
    print_header "Docker Container Status"
    echo ""
    
    # Check main services
    services=("hotel-mapping-frontend" "hotel-mapping-backend" "hotel-mapping-mongodb")
    
    for service in "${services[@]}"; do
        if docker ps --format "table {{.Names}}" | grep -q "$service"; then
            status=$(docker inspect --format='{{.State.Status}}' "$service" 2>/dev/null)
            health=$(docker inspect --format='{{.State.Health.Status}}' "$service" 2>/dev/null)
            
            if [[ "$status" == "running" ]]; then
                if [[ "$health" == "healthy" || "$health" == "" ]]; then
                    print_success "$service: Running & Healthy"
                else
                    print_warning "$service: Running but $health"
                fi
            else
                print_error "$service: $status"
            fi
        else
            print_error "$service: Not found"
        fi
    done
    echo ""
}

# Function to check service endpoints
check_endpoints() {
    print_header "Service Endpoint Health"
    echo ""
    
    # Check frontend
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200"; then
        print_success "Frontend (http://localhost:3000): Accessible"
    else
        print_error "Frontend (http://localhost:3000): Not accessible"
    fi
    
    # Check backend API
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/api/hotels | grep -q "200"; then
        print_success "Backend API (http://localhost:8001): Accessible"
    else
        print_error "Backend API (http://localhost:8001): Not accessible"
    fi
    
    # Check backend docs
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/docs | grep -q "200"; then
        print_success "API Documentation (http://localhost:8001/docs): Accessible"
    else
        print_error "API Documentation: Not accessible"
    fi
    
    echo ""
}

# Function to show resource usage
show_resources() {
    print_header "Resource Usage"
    echo ""
    
    # Docker stats
    print_info "Container Resource Usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | grep hotel-mapping
    echo ""
    
    # System resources
    print_info "System Resources:"
    echo "  CPU Usage: $(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//' 2>/dev/null || echo "N/A")"
    echo "  Memory: $(free -h | grep Mem | awk '{print $3 "/" $2}' 2>/dev/null || echo "N/A")"
    echo "  Disk: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 " used)"}' 2>/dev/null || echo "N/A")"
    echo ""
}

# Function to show Node.js specific info
show_nodejs_info() {
    print_header "Node.js Information"
    echo ""
    
    # Check Node.js version in frontend container
    if docker ps --format "table {{.Names}}" | grep -q "hotel-mapping-frontend"; then
        node_version=$(docker exec hotel-mapping-frontend node --version 2>/dev/null || echo "N/A")
        npm_version=$(docker exec hotel-mapping-frontend npm --version 2>/dev/null || echo "N/A")
        yarn_version=$(docker exec hotel-mapping-frontend yarn --version 2>/dev/null || echo "N/A")
        
        print_info "Frontend Container:"
        echo "  Node.js: $node_version"
        echo "  NPM: $npm_version"
        echo "  Yarn: $yarn_version"
        
        # Check memory usage
        if command -v docker >/dev/null 2>&1; then
            memory_usage=$(docker exec hotel-mapping-frontend sh -c "cat /proc/meminfo | grep MemAvailable" 2>/dev/null || echo "N/A")
            echo "  Available Memory: $memory_usage"
        fi
    else
        print_warning "Frontend container not running"
    fi
    echo ""
}

# Function to show database info
show_database_info() {
    print_header "Database Information"
    echo ""
    
    if docker ps --format "table {{.Names}}" | grep -q "hotel-mapping-mongodb"; then
        # Check MongoDB status
        db_status=$(docker exec hotel-mapping-mongodb mongosh --quiet --eval "db.adminCommand('ping').ok" 2>/dev/null || echo "0")
        
        if [[ "$db_status" == "1" ]]; then
            print_success "MongoDB: Connected"
            
            # Get database stats
            hotel_count=$(docker exec hotel-mapping-mongodb mongosh hotel_mapping --quiet --eval "db.hotels.countDocuments()" 2>/dev/null || echo "N/A")
            user_count=$(docker exec hotel-mapping-mongodb mongosh hotel_mapping --quiet --eval "db.users.countDocuments()" 2>/dev/null || echo "N/A")
            
            print_info "Database Statistics:"
            echo "  Hotels: $hotel_count"
            echo "  Users: $user_count"
            
            # Check indexes
            indexes=$(docker exec hotel-mapping-mongodb mongosh hotel_mapping --quiet --eval "db.hotels.getIndexes().length" 2>/dev/null || echo "N/A")
            echo "  Hotel Indexes: $indexes"
        else
            print_error "MongoDB: Connection failed"
        fi
    else
        print_warning "MongoDB container not running"
    fi
    echo ""
}

# Function to show recent logs
show_recent_logs() {
    print_header "Recent Log Summary"
    echo ""
    
    print_info "Last 5 lines from each service:"
    echo ""
    
    # Frontend logs
    echo -e "${CYAN}Frontend:${NC}"
    docker logs --tail 5 hotel-mapping-frontend 2>/dev/null | tail -5 || echo "  No logs available"
    echo ""
    
    # Backend logs
    echo -e "${CYAN}Backend:${NC}"
    docker logs --tail 5 hotel-mapping-backend 2>/dev/null | tail -5 || echo "  No logs available"
    echo ""
    
    # MongoDB logs
    echo -e "${CYAN}MongoDB:${NC}"
    docker logs --tail 5 hotel-mapping-mongodb 2>/dev/null | tail -5 || echo "  No logs available"
    echo ""
}

# Function to show network info
show_network_info() {
    print_header "Network Information"
    echo ""
    
    # Check Docker network
    if docker network ls | grep -q "hotel-network"; then
        print_success "Docker network 'hotel-network': Active"
        
        # Show network details
        network_info=$(docker network inspect hotel-network --format "{{range .Containers}}{{.Name}}: {{.IPv4Address}} {{end}}" 2>/dev/null)
        if [[ -n "$network_info" ]]; then
            print_info "Connected containers:"
            echo "  $network_info"
        fi
    else
        print_warning "Docker network 'hotel-network': Not found"
    fi
    
    # Check port bindings
    print_info "Port Mappings:"
    docker ps --format "table {{.Names}}\t{{.Ports}}" | grep hotel-mapping | while read line; do
        echo "  $line"
    done
    echo ""
}

# Function to perform quick health checks
quick_health_check() {
    print_header "Quick Health Check"
    echo ""
    
    # Check if all services respond
    health_score=0
    total_checks=3
    
    # Frontend check
    if curl -s -f http://localhost:3000 >/dev/null 2>&1; then
        ((health_score++))
    fi
    
    # Backend check
    if curl -s -f http://localhost:8001/api/hotels >/dev/null 2>&1; then
        ((health_score++))
    fi
    
    # Database check
    if docker exec hotel-mapping-mongodb mongosh --quiet --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
        ((health_score++))
    fi
    
    health_percentage=$((health_score * 100 / total_checks))
    
    if [[ $health_score -eq $total_checks ]]; then
        print_success "System Health: $health_percentage% (All services operational)"
    elif [[ $health_score -gt 0 ]]; then
        print_warning "System Health: $health_percentage% (Some services may have issues)"
    else
        print_error "System Health: $health_percentage% (Major issues detected)"
    fi
    echo ""
}

# Main execution
case "${1:-}" in
    "full")
        check_containers
        check_endpoints
        show_resources
        show_nodejs_info
        show_database_info
        show_network_info
        show_recent_logs
        ;;
    "health")
        quick_health_check
        check_containers
        check_endpoints
        ;;
    "resources")
        show_resources
        show_nodejs_info
        ;;
    "database"|"db")
        show_database_info
        ;;
    "logs")
        show_recent_logs
        ;;
    "network")
        show_network_info
        ;;
    *)
        echo "Hotel Mapping Application Monitor"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  full       Full system monitoring report"
        echo "  health     Quick health check"
        echo "  resources  Resource usage and Node.js info"
        echo "  database   Database status and statistics"
        echo "  logs       Recent log summary"
        echo "  network    Network and connectivity info"
        echo ""
        echo "Examples:"
        echo "  $0 full      # Complete system report"
        echo "  $0 health    # Quick health check"
        echo "  $0 resources # Resource monitoring"
        echo ""
        print_info "Running quick health check..."
        quick_health_check
        ;;
esac