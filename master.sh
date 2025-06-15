#!/bin/bash

# Master Control Script for Hotel Mapping Application
echo "🏨 Hotel Mapping Application - Master Control Center"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${PURPLE}[MASTER]${NC} $1"
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

# Function to show application status
show_status() {
    print_header "Hotel Mapping Application Status"
    echo ""
    
    # Check if scripts exist
    scripts=("deploy.sh" "monitor.sh" "dev-tools.sh" "performance-test.sh" "backup-restore.sh" "setup-env.sh")
    
    print_info "Available Tools:"
    for script in "${scripts[@]}"; do
        if [ -x "$script" ]; then
            print_success "✅ $script"
        else
            print_warning "⚠️  $script (not executable or missing)"
        fi
    done
    
    echo ""
    
    # Check Docker containers
    print_info "Container Status:"
    if command -v docker &> /dev/null; then
        if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "hotel-mapping"; then
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "hotel-mapping" | while read line; do
                echo "  $line"
            done
        else
            print_warning "No Hotel Mapping containers running"
        fi
    else
        print_warning "Docker not available"
    fi
    
    echo ""
    
    # Check environment files
    print_info "Environment Configuration:"
    env_files=(".env" "frontend/.env" "backend/.env" "frontend/.env.docker" "backend/.env.docker")
    
    for env_file in "${env_files[@]}"; do
        if [ -f "$env_file" ]; then
            print_success "✅ $env_file"
        else
            print_warning "⚠️  $env_file (missing)"
        fi
    done
    
    echo ""
    
    # Quick health check
    print_info "Service Health Check:"
    if curl -s -f http://localhost:3000 > /dev/null 2>&1; then
        print_success "✅ Frontend (http://localhost:3000)"
    else
        print_warning "⚠️  Frontend not accessible"
    fi
    
    if curl -s -f http://localhost:8001/api/hotels > /dev/null 2>&1; then
        print_success "✅ Backend API (http://localhost:8001)"
    else
        print_warning "⚠️  Backend API not accessible"
    fi
}

# Function to show quick start guide
show_quick_start() {
    print_header "Quick Start Guide"
    echo ""
    
    echo -e "${CYAN}🚀 Getting Started:${NC}"
    echo "1. Setup environment:     ./master.sh setup"
    echo "2. Deploy application:    ./master.sh deploy"
    echo "3. Monitor status:        ./master.sh monitor"
    echo "4. Run performance tests: ./master.sh test"
    echo "5. Create backup:         ./master.sh backup"
    echo ""
    
    echo -e "${CYAN}📦 Docker Deployment:${NC}"
    echo "• Development (Node.js 21): ./deploy.sh dev"
    echo "• Stable (Node.js 20 LTS):  ./deploy.sh dev-lts"
    echo "• Production:               ./deploy.sh prod"
    echo ""
    
    echo -e "${CYAN}🔧 Development Tools:${NC}"
    echo "• Access container shells:  ./dev-tools.sh shell"
    echo "• Node.js tools:            ./dev-tools.sh node"
    echo "• Python tools:             ./dev-tools.sh python"
    echo "• Database tools:           ./dev-tools.sh database"
    echo ""
    
    echo -e "${CYAN}📊 Monitoring & Testing:${NC}"
    echo "• Full system monitor:      ./monitor.sh full"
    echo "• Performance tests:        ./performance-test.sh all"
    echo "• Health check:             ./monitor.sh health"
    echo ""
    
    echo -e "${CYAN}💾 Backup & Restore:${NC}"
    echo "• Complete backup:          ./backup-restore.sh complete"
    echo "• List backups:             ./backup-restore.sh list"
    echo "• Restore database:         ./backup-restore.sh restore-db <file>"
    echo ""
}

# Function to run initial setup
run_setup() {
    print_header "Running Initial Setup"
    
    # Setup environment
    if [ -x "./setup-env.sh" ]; then
        print_info "Setting up environment files..."
        ./setup-env.sh
    else
        print_error "setup-env.sh not found or not executable"
        return 1
    fi
    
    # Validate Docker setup
    if [ -x "./validate-docker.sh" ]; then
        print_info "Validating Docker setup..."
        ./validate-docker.sh
    else
        print_warning "validate-docker.sh not found"
    fi
    
    print_success "Setup completed!"
}

# Function to deploy application
run_deploy() {
    local environment="${1:-dev}"
    
    print_header "Deploying Hotel Mapping Application"
    
    if [ -x "./deploy.sh" ]; then
        print_info "Deploying in $environment mode..."
        ./deploy.sh "$environment"
    else
        print_error "deploy.sh not found or not executable"
        return 1
    fi
}

# Function to run monitoring
run_monitor() {
    local mode="${1:-health}"
    
    print_header "Running System Monitor"
    
    if [ -x "./monitor.sh" ]; then
        ./monitor.sh "$mode"
    else
        print_error "monitor.sh not found or not executable"
        return 1
    fi
}

# Function to run performance tests
run_performance_test() {
    local test_type="${1:-basic}"
    
    print_header "Running Performance Tests"
    
    if [ -x "./performance-test.sh" ]; then
        ./performance-test.sh "$test_type"
    else
        print_error "performance-test.sh not found or not executable"
        return 1
    fi
}

# Function to create backup
run_backup() {
    local backup_type="${1:-complete}"
    
    print_header "Creating Backup"
    
    if [ -x "./backup-restore.sh" ]; then
        ./backup-restore.sh "$backup_type"
    else
        print_error "backup-restore.sh not found or not executable"
        return 1
    fi
}

# Function to show logs
show_logs() {
    print_header "Application Logs"
    
    if [ -x "./deploy.sh" ]; then
        ./deploy.sh logs
    else
        print_error "deploy.sh not found or not executable"
        return 1
    fi
}

# Function to stop all services
stop_services() {
    print_header "Stopping All Services"
    
    if [ -x "./deploy.sh" ]; then
        ./deploy.sh stop
    else
        print_error "deploy.sh not found or not executable"
        return 1
    fi
}

# Function to show version information
show_version() {
    print_header "Version Information"
    echo ""
    
    print_info "Hotel Mapping Application v1.0"
    print_info "Built with:"
    echo "  • React 19 + Node.js 20/21"
    echo "  • FastAPI + Python 3.11"
    echo "  • MongoDB 7"
    echo "  • Mapbox GL JS"
    echo "  • Docker & Kubernetes"
    echo ""
    
    if [ -x "./node-versions.sh" ]; then
        ./node-versions.sh
    fi
    
    echo ""
    print_info "System Information:"
    echo "  • OS: $(uname -s) $(uname -r)"
    echo "  • Docker: $(docker --version 2>/dev/null || echo 'Not installed')"
    echo "  • Docker Compose: $(docker-compose --version 2>/dev/null || echo 'Not installed')"
    echo "  • Node.js: $(node --version 2>/dev/null || echo 'Not installed')"
    echo "  • Python: $(python3 --version 2>/dev/null || echo 'Not installed')"
}

# Function to show all available commands
show_help() {
    echo -e "${PURPLE}🏨 Hotel Mapping Application - Master Control Center${NC}"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo -e "${CYAN}Core Commands:${NC}"
    echo "  status        Show application status and health"
    echo "  setup         Run initial environment setup"
    echo "  deploy [env]  Deploy application (dev/dev-lts/prod)"
    echo "  stop          Stop all services"
    echo "  logs          Show application logs"
    echo ""
    echo -e "${CYAN}Monitoring & Testing:${NC}"
    echo "  monitor [type]  Run system monitoring (health/full/resources)"
    echo "  test [type]     Run performance tests (basic/stress/all)"
    echo "  backup [type]   Create backup (database/complete)"
    echo ""
    echo -e "${CYAN}Information:${NC}"
    echo "  quickstart    Show quick start guide"
    echo "  version       Show version information"
    echo "  help          Show this help message"
    echo ""
    echo -e "${CYAN}Examples:${NC}"
    echo "  $0 setup                    # Initial setup"
    echo "  $0 deploy dev              # Deploy development environment"
    echo "  $0 deploy dev-lts          # Deploy with Node.js 20 LTS"
    echo "  $0 monitor full            # Full system monitoring"
    echo "  $0 test all                # Run all performance tests"
    echo "  $0 backup complete         # Create complete backup"
    echo ""
    echo -e "${CYAN}Direct Tool Access:${NC}"
    echo "  ./deploy.sh [cmd]          # Docker deployment"
    echo "  ./dev-tools.sh [cmd]       # Development tools"
    echo "  ./monitor.sh [cmd]         # System monitoring"
    echo "  ./performance-test.sh [cmd] # Performance testing"
    echo "  ./backup-restore.sh [cmd]  # Backup & restore"
    echo ""
    echo -e "${YELLOW}💡 Tip: Run './master.sh quickstart' for a getting started guide${NC}"
}

# Function to run interactive mode
run_interactive() {
    while true; do
        echo ""
        print_header "Hotel Mapping Application - Interactive Mode"
        echo ""
        echo "1) Show Status"
        echo "2) Deploy Application"
        echo "3) Monitor System"
        echo "4) Run Performance Test"
        echo "5) Create Backup"
        echo "6) Show Logs"
        echo "7) Stop Services"
        echo "8) Development Tools"
        echo "9) Quick Start Guide"
        echo "0) Exit"
        echo ""
        read -p "Select an option [0-9]: " choice
        
        case $choice in
            1) show_status ;;
            2)
                echo "Select deployment environment:"
                echo "1) Development (Node.js 21)"
                echo "2) Development LTS (Node.js 20)"
                echo "3) Production"
                read -p "Choice [1-3]: " deploy_choice
                case $deploy_choice in
                    1) run_deploy "dev" ;;
                    2) run_deploy "dev-lts" ;;
                    3) run_deploy "prod" ;;
                    *) print_warning "Invalid choice" ;;
                esac
                ;;
            3)
                echo "Select monitoring type:"
                echo "1) Health Check"
                echo "2) Full Report"
                echo "3) Resources"
                read -p "Choice [1-3]: " monitor_choice
                case $monitor_choice in
                    1) run_monitor "health" ;;
                    2) run_monitor "full" ;;
                    3) run_monitor "resources" ;;
                    *) print_warning "Invalid choice" ;;
                esac
                ;;
            4)
                echo "Select test type:"
                echo "1) Basic Load Test"
                echo "2) Stress Test"
                echo "3) All Tests"
                read -p "Choice [1-3]: " test_choice
                case $test_choice in
                    1) run_performance_test "basic" ;;
                    2) run_performance_test "stress" ;;
                    3) run_performance_test "all" ;;
                    *) print_warning "Invalid choice" ;;
                esac
                ;;
            5)
                echo "Select backup type:"
                echo "1) Database Only"
                echo "2) Complete Backup"
                read -p "Choice [1-2]: " backup_choice
                case $backup_choice in
                    1) run_backup "database" ;;
                    2) run_backup "complete" ;;
                    *) print_warning "Invalid choice" ;;
                esac
                ;;
            6) show_logs ;;
            7) stop_services ;;
            8)
                if [ -x "./dev-tools.sh" ]; then
                    ./dev-tools.sh
                else
                    print_error "dev-tools.sh not found"
                fi
                ;;
            9) show_quick_start ;;
            0) 
                print_success "Goodbye! 👋"
                exit 0
                ;;
            *) print_warning "Invalid option. Please try again." ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Main script execution
case "${1:-}" in
    "status")
        show_status
        ;;
    "setup")
        run_setup
        ;;
    "deploy")
        run_deploy "$2"
        ;;
    "monitor")
        run_monitor "$2"
        ;;
    "test")
        run_performance_test "$2"
        ;;
    "backup")
        run_backup "$2"
        ;;
    "logs")
        show_logs
        ;;
    "stop")
        stop_services
        ;;
    "quickstart")
        show_quick_start
        ;;
    "version")
        show_version
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    "interactive"|"i")
        run_interactive
        ;;
    "")
        # No arguments - show status and help
        show_status
        echo ""
        echo -e "${YELLOW}💡 Run './master.sh help' for all available commands${NC}"
        echo -e "${YELLOW}💡 Run './master.sh interactive' for interactive mode${NC}"
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac