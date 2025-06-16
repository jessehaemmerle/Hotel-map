#!/bin/bash

# Development tools for Hotel Mapping Application
echo "🏨 Hotel Mapping Application - Development Tools"
echo "==============================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${PURPLE}[DEV-TOOLS]${NC} $1"
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

# Function to run development commands inside containers
dev_shell() {
    print_header "Development Shell Access"
    echo ""
    echo "Choose a container to access:"
    echo "1) Frontend (Node.js)"
    echo "2) Backend (Python)"
    echo "3) Database (MongoDB)"
    read -p "Enter choice [1-3]: " choice
    
    case $choice in
        1)
            print_info "Accessing frontend container..."
            docker exec -it hotel-mapping-frontend sh
            ;;
        2)
            print_info "Accessing backend container..."
            docker exec -it hotel-mapping-backend bash
            ;;
        3)
            print_info "Accessing MongoDB container..."
            docker exec -it hotel-mapping-mongodb mongosh hotel_mapping
            ;;
        *)
            print_warning "Invalid choice"
            ;;
    esac
}

# Function to run Node.js development commands
node_dev() {
    print_header "Node.js Development Commands"
    echo ""
    echo "Available commands:"
    echo "1) Install dependencies"
    echo "2) Run tests"
    echo "3) Lint code"
    echo "4) Check for updates"
    echo "5) Clear cache"
    echo "6) Bundle analyzer"
    read -p "Enter choice [1-6]: " choice
    
    case $choice in
        1)
            print_info "Installing dependencies..."
            docker exec hotel-mapping-frontend yarn install
            ;;
        2)
            print_info "Running tests..."
            docker exec hotel-mapping-frontend yarn test --watchAll=false --passWithNoTests
            ;;
        3)
            print_info "Linting code..."
            docker exec hotel-mapping-frontend yarn lint 2>/dev/null || echo "Lint command not configured"
            ;;
        4)
            print_info "Checking for updates..."
            docker exec hotel-mapping-frontend yarn outdated
            ;;
        5)
            print_info "Clearing cache..."
            docker exec hotel-mapping-frontend yarn cache clean
            ;;
        6)
            print_info "Analyzing bundle size..."
            docker exec hotel-mapping-frontend yarn build
            docker exec hotel-mapping-frontend npx webpack-bundle-analyzer build/static/js/*.js 2>/dev/null || echo "Bundle analyzer not available"
            ;;
        *)
            print_warning "Invalid choice"
            ;;
    esac
}

# Function to run Python development commands
python_dev() {
    print_header "Python Development Commands"
    echo ""
    echo "Available commands:"
    echo "1) Install dependencies"
    echo "2) Run tests"
    echo "3) Format code (black)"
    echo "4) Lint code (flake8)"
    echo "5) Type check (mypy)"
    echo "6) Security scan"
    read -p "Enter choice [1-6]: " choice
    
    case $choice in
        1)
            print_info "Installing dependencies..."
            docker exec hotel-mapping-backend pip install -r requirements.txt
            ;;
        2)
            print_info "Running tests..."
            docker exec hotel-mapping-backend python -m pytest
            ;;
        3)
            print_info "Formatting code with black..."
            docker exec hotel-mapping-backend black .
            ;;
        4)
            print_info "Linting with flake8..."
            docker exec hotel-mapping-backend flake8 .
            ;;
        5)
            print_info "Type checking with mypy..."
            docker exec hotel-mapping-backend mypy .
            ;;
        6)
            print_info "Security scan..."
            docker exec hotel-mapping-backend pip-audit 2>/dev/null || pip install pip-audit && pip-audit
            ;;
        *)
            print_warning "Invalid choice"
            ;;
    esac
}

# Function to manage database
database_dev() {
    print_header "Database Development Tools"
    echo ""
    echo "Available commands:"
    echo "1) Show collections"
    echo "2) Show sample hotel data"
    echo "3) Show indexes"
    echo "4) Database statistics"
    echo "5) Create test data"
    echo "6) Clear all data"
    read -p "Enter choice [1-6]: " choice
    
    case $choice in
        1)
            print_info "Showing collections..."
            docker exec hotel-mapping-mongodb mongosh hotel_mapping --eval "db.getCollectionNames()"
            ;;
        2)
            print_info "Showing sample hotel data..."
            docker exec hotel-mapping-mongodb mongosh hotel_mapping --eval "db.hotels.find().limit(3).pretty()"
            ;;
        3)
            print_info "Showing indexes..."
            docker exec hotel-mapping-mongodb mongosh hotel_mapping --eval "db.hotels.getIndexes()"
            ;;
        4)
            print_info "Database statistics..."
            docker exec hotel-mapping-mongodb mongosh hotel_mapping --eval "db.stats()"
            ;;
        5)
            print_warning "This will create test data. Continue? (y/N)"
            read -p "" confirm
            if [[ $confirm == [yY] ]]; then
                print_info "Creating test data..."
                docker exec hotel-mapping-mongodb mongosh hotel_mapping --eval "
                db.hotels.insertMany([
                    {
                        id: 'test-hotel-' + new Date().getTime(),
                        owner_id: 'test-owner',
                        name: 'Test Remote Work Hotel',
                        description: 'Perfect for testing remote work features',
                        price: 99.99,
                        location: { type: 'Point', coordinates: [0, 0] },
                        amenities: ['wifi', 'desk', 'coffee'],
                        home_office_amenities: ['fast-wifi', 'ergonomic-chair'],
                        rating: 4.5,
                        address: 'Test Address',
                        created_at: new Date()
                    }
                ])
                "
                print_success "Test data created"
            fi
            ;;
        6)
            print_warning "This will DELETE ALL DATA. Are you sure? (type 'DELETE' to confirm)"
            read -p "" confirm
            if [[ $confirm == "DELETE" ]]; then
                print_info "Clearing all data..."
                docker exec hotel-mapping-mongodb mongosh hotel_mapping --eval "db.hotels.deleteMany({}); db.users.deleteMany({})"
                print_success "All data cleared"
            else
                print_info "Operation cancelled"
            fi
            ;;
        *)
            print_warning "Invalid choice"
            ;;
    esac
}

# Function to debug issues
debug_tools() {
    print_header "Debug Tools"
    echo ""
    echo "Available tools:"
    echo "1) View live logs"
    echo "2) Check container processes"
    echo "3) Network diagnostics"
    echo "4) Performance monitoring"
    echo "5) Error log search"
    echo "6) Container resource usage"
    read -p "Enter choice [1-6]: " choice
    
    case $choice in
        1)
            echo "Which service logs?"
            echo "1) Frontend  2) Backend  3) Database  4) All"
            read -p "Choice: " log_choice
            case $log_choice in
                1) docker logs -f hotel-mapping-frontend ;;
                2) docker logs -f hotel-mapping-backend ;;
                3) docker logs -f hotel-mapping-mongodb ;;
                4) docker-compose logs -f ;;
                *) print_warning "Invalid choice" ;;
            esac
            ;;
        2)
            print_info "Container processes..."
            docker exec hotel-mapping-frontend ps aux 2>/dev/null || echo "Frontend not accessible"
            docker exec hotel-mapping-backend ps aux 2>/dev/null || echo "Backend not accessible"
            ;;
        3)
            print_info "Network diagnostics..."
            docker exec hotel-mapping-frontend ping -c 3 hotel-mapping-backend 2>/dev/null || echo "Network test failed"
            docker exec hotel-mapping-backend ping -c 3 hotel-mapping-mongodb 2>/dev/null || echo "Database connection test failed"
            ;;
        4)
            print_info "Performance monitoring (press Ctrl+C to stop)..."
            docker stats hotel-mapping-frontend hotel-mapping-backend hotel-mapping-mongodb
            ;;
        5)
            print_info "Searching for errors in logs..."
            echo "Frontend errors:"
            docker logs hotel-mapping-frontend 2>&1 | grep -i error | tail -5
            echo "Backend errors:"
            docker logs hotel-mapping-backend 2>&1 | grep -i error | tail -5
            ;;
        6)
            print_info "Detailed container resource usage..."
            docker exec hotel-mapping-frontend sh -c "cat /proc/meminfo | head -5" 2>/dev/null || echo "Frontend memory info unavailable"
            docker exec hotel-mapping-backend sh -c "cat /proc/meminfo | head -5" 2>/dev/null || echo "Backend memory info unavailable"
            ;;
        *)
            print_warning "Invalid choice"
            ;;
    esac
}

# Function to manage Docker environments
docker_management() {
    print_header "Docker Environment Management"
    echo ""
    echo "Available commands:"
    echo "1) Switch to Node.js 20 LTS"
    echo "2) Switch to Node.js 21 Latest"
    echo "3) Rebuild specific service"
    echo "4) Clean unused images"
    echo "5) Reset environment"
    echo "6) Export/Import images"
    read -p "Enter choice [1-6]: " choice
    
    case $choice in
        1)
            print_info "Switching to Node.js 20 LTS..."
            docker-compose down
            docker-compose -f docker-compose.lts.yml up -d --build
            ;;
        2)
            print_info "Switching to Node.js 21 Latest..."
            docker-compose -f docker-compose.lts.yml down
            docker-compose up -d --build
            ;;
        3)
            echo "Which service to rebuild?"
            echo "1) Frontend  2) Backend  3) All"
            read -p "Choice: " rebuild_choice
            case $rebuild_choice in
                1) docker-compose up -d --build frontend ;;
                2) docker-compose up -d --build backend ;;
                3) docker-compose up -d --build ;;
                *) print_warning "Invalid choice" ;;
            esac
            ;;
        4)
            print_info "Cleaning unused Docker images..."
            docker image prune -f
            docker system prune -f
            ;;
        5)
            print_warning "This will reset the entire environment. Continue? (y/N)"
            read -p "" confirm
            if [[ $confirm == [yY] ]]; then
                print_info "Resetting environment..."
                docker-compose down -v
                docker-compose -f docker-compose.lts.yml down -v
                docker-compose up -d --build
            fi
            ;;
        6)
            echo "1) Export images  2) Import images"
            read -p "Choice: " export_choice
            case $export_choice in
                1)
                    print_info "Exporting images..."
                    docker save hotel-mapping-frontend hotel-mapping-backend > hotel-mapping-images.tar
                    print_success "Images exported to hotel-mapping-images.tar"
                    ;;
                2)
                    if [[ -f "hotel-mapping-images.tar" ]]; then
                        print_info "Importing images..."
                        docker load < hotel-mapping-images.tar
                        print_success "Images imported"
                    else
                        print_warning "hotel-mapping-images.tar not found"
                    fi
                    ;;
                *) print_warning "Invalid choice" ;;
            esac
            ;;
        *)
            print_warning "Invalid choice"
            ;;
    esac
}

# Main menu
case "${1:-}" in
    "shell")
        dev_shell
        ;;
    "node")
        node_dev
        ;;
    "python")
        python_dev
        ;;
    "database"|"db")
        database_dev
        ;;
    "debug")
        debug_tools
        ;;
    "docker")
        docker_management
        ;;
    *)
        echo "Hotel Mapping Application - Development Tools"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  shell      Access container shells"
        echo "  node       Node.js development tools"
        echo "  python     Python development tools"
        echo "  database   Database management tools"
        echo "  debug      Debug and troubleshooting tools"
        echo "  docker     Docker environment management"
        echo ""
        echo "Examples:"
        echo "  $0 shell    # Access container shells"
        echo "  $0 node     # Node.js development commands"
        echo "  $0 debug    # Debug tools and diagnostics"
        echo ""
        print_info "Choose a development tool category above or run with a specific command"
        ;;
esac
