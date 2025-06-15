#!/bin/bash

# Backup and Restore System for Hotel Mapping Application
echo "🏨 Hotel Mapping Application - Backup & Restore System"
echo "====================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${PURPLE}[BACKUP]${NC} $1"
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
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CONTAINER_MONGODB="hotel-mapping-mongodb"
CONTAINER_BACKEND="hotel-mapping-backend"
CONTAINER_FRONTEND="hotel-mapping-frontend"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to check if containers are running
check_containers() {
    print_info "Checking container status..."
    
    if ! docker ps | grep -q "$CONTAINER_MONGODB"; then
        print_error "MongoDB container is not running"
        return 1
    fi
    
    if ! docker ps | grep -q "$CONTAINER_BACKEND"; then
        print_warning "Backend container is not running"
    fi
    
    if ! docker ps | grep -q "$CONTAINER_FRONTEND"; then
        print_warning "Frontend container is not running"
    fi
    
    return 0
}

# Function to backup MongoDB database
backup_database() {
    print_header "Backing up MongoDB database..."
    
    local backup_name="mongodb_backup_$TIMESTAMP"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    # Create backup directory
    mkdir -p "$backup_path"
    
    # Backup database
    print_info "Creating database dump..."
    if docker exec "$CONTAINER_MONGODB" mongodump --out "/tmp/$backup_name"; then
        print_success "Database dump created successfully"
        
        # Copy backup from container
        print_info "Copying backup from container..."
        if docker cp "$CONTAINER_MONGODB:/tmp/$backup_name" "$backup_path/"; then
            print_success "Database backup saved to: $backup_path"
            
            # Cleanup container
            docker exec "$CONTAINER_MONGODB" rm -rf "/tmp/$backup_name"
            
            # Create metadata file
            cat > "$backup_path/backup_info.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "type": "mongodb",
  "database": "hotel_mapping",
  "container": "$CONTAINER_MONGODB",
  "size": "$(du -sh "$backup_path" | cut -f1)",
  "created_by": "backup-restore.sh",
  "version": "1.0"
}
EOF
            
            # Compress backup
            print_info "Compressing backup..."
            tar -czf "$backup_path.tar.gz" -C "$BACKUP_DIR" "$backup_name"
            rm -rf "$backup_path"
            
            print_success "Compressed backup created: $backup_path.tar.gz"
        else
            print_error "Failed to copy backup from container"
            return 1
        fi
    else
        print_error "Failed to create database dump"
        return 1
    fi
}

# Function to backup environment files
backup_environment() {
    print_header "Backing up environment configuration..."
    
    local env_backup_path="$BACKUP_DIR/environment_backup_$TIMESTAMP"
    mkdir -p "$env_backup_path"
    
    # Backup environment files
    if [ -f ".env" ]; then
        cp ".env" "$env_backup_path/"
        print_success "Root .env backed up"
    fi
    
    if [ -f "frontend/.env" ]; then
        mkdir -p "$env_backup_path/frontend"
        cp "frontend/.env" "$env_backup_path/frontend/"
        print_success "Frontend .env backed up"
    fi
    
    if [ -f "backend/.env" ]; then
        mkdir -p "$env_backup_path/backend"
        cp "backend/.env" "$env_backup_path/backend/"
        print_success "Backend .env backed up"
    fi
    
    # Backup Docker environment files
    if [ -f "frontend/.env.docker" ]; then
        cp "frontend/.env.docker" "$env_backup_path/frontend/"
        print_success "Frontend Docker .env backed up"
    fi
    
    if [ -f "backend/.env.docker" ]; then
        cp "backend/.env.docker" "$env_backup_path/backend/"
        print_success "Backend Docker .env backed up"
    fi
    
    # Create metadata
    cat > "$env_backup_path/backup_info.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "type": "environment",
  "files_backed_up": [
    $(find "$env_backup_path" -name "*.env*" -o -name ".env" | wc -l)
  ],
  "created_by": "backup-restore.sh",
  "version": "1.0"
}
EOF
    
    # Compress environment backup
    tar -czf "$env_backup_path.tar.gz" -C "$BACKUP_DIR" "environment_backup_$TIMESTAMP"
    rm -rf "$env_backup_path"
    
    print_success "Environment backup created: $env_backup_path.tar.gz"
}

# Function to backup application code
backup_application() {
    print_header "Backing up application code..."
    
    local app_backup_path="$BACKUP_DIR/application_backup_$TIMESTAMP"
    mkdir -p "$app_backup_path"
    
    # Backup source code (excluding node_modules, __pycache__, etc.)
    print_info "Backing up source code..."
    
    # Backend code
    if [ -d "backend" ]; then
        mkdir -p "$app_backup_path/backend"
        rsync -av --exclude='__pycache__' --exclude='*.pyc' --exclude='.pytest_cache' \
              backend/ "$app_backup_path/backend/"
        print_success "Backend code backed up"
    fi
    
    # Frontend code
    if [ -d "frontend" ]; then
        mkdir -p "$app_backup_path/frontend"
        rsync -av --exclude='node_modules' --exclude='build' --exclude='.cache' \
              frontend/ "$app_backup_path/frontend/"
        print_success "Frontend code backed up"
    fi
    
    # Docker files
    for file in Dockerfile.* docker-compose*.yml .dockerignore; do
        if [ -f "$file" ]; then
            cp "$file" "$app_backup_path/"
        fi
    done
    
    # Scripts
    for file in *.sh; do
        if [ -f "$file" ]; then
            cp "$file" "$app_backup_path/"
        fi
    done
    
    # Kubernetes files
    if [ -d "k8s" ]; then
        cp -r k8s "$app_backup_path/"
        print_success "Kubernetes manifests backed up"
    fi
    
    # Documentation
    for file in README*.md QUICK-START.md; do
        if [ -f "$file" ]; then
            cp "$file" "$app_backup_path/"
        fi
    done
    
    # Create metadata
    cat > "$app_backup_path/backup_info.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "type": "application",
  "git_commit": "$(git rev-parse HEAD 2>/dev/null || echo 'N/A')",
  "git_branch": "$(git branch --show-current 2>/dev/null || echo 'N/A')",
  "created_by": "backup-restore.sh",
  "version": "1.0"
}
EOF
    
    # Compress application backup
    tar -czf "$app_backup_path.tar.gz" -C "$BACKUP_DIR" "application_backup_$TIMESTAMP"
    rm -rf "$app_backup_path"
    
    print_success "Application backup created: $app_backup_path.tar.gz"
}

# Function to create complete backup
create_complete_backup() {
    print_header "Creating complete system backup..."
    
    local complete_backup_path="$BACKUP_DIR/complete_backup_$TIMESTAMP"
    mkdir -p "$complete_backup_path"
    
    # Check containers
    if ! check_containers; then
        print_warning "Some containers are not running. Backup may be incomplete."
    fi
    
    # Create individual backups
    backup_database
    backup_environment
    backup_application
    
    # Move all backups to complete backup directory
    mv "$BACKUP_DIR"/mongodb_backup_$TIMESTAMP.tar.gz "$complete_backup_path/" 2>/dev/null
    mv "$BACKUP_DIR"/environment_backup_$TIMESTAMP.tar.gz "$complete_backup_path/" 2>/dev/null
    mv "$BACKUP_DIR"/application_backup_$TIMESTAMP.tar.gz "$complete_backup_path/" 2>/dev/null
    
    # Create complete backup metadata
    cat > "$complete_backup_path/backup_manifest.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "type": "complete",
  "components": [
    "mongodb_backup_$TIMESTAMP.tar.gz",
    "environment_backup_$TIMESTAMP.tar.gz",
    "application_backup_$TIMESTAMP.tar.gz"
  ],
  "system_info": {
    "hostname": "$(hostname)",
    "os": "$(uname -s)",
    "docker_version": "$(docker --version | cut -d' ' -f3 | tr -d ',')",
    "compose_version": "$(docker-compose --version | cut -d' ' -f4 | tr -d ',')"
  },
  "created_by": "backup-restore.sh",
  "version": "1.0"
}
EOF
    
    # Create final compressed backup
    tar -czf "$BACKUP_DIR/hotel_mapping_complete_backup_$TIMESTAMP.tar.gz" \
        -C "$BACKUP_DIR" "complete_backup_$TIMESTAMP"
    rm -rf "$complete_backup_path"
    
    print_success "Complete backup created: $BACKUP_DIR/hotel_mapping_complete_backup_$TIMESTAMP.tar.gz"
}

# Function to list available backups
list_backups() {
    print_header "Available backups:"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR")" ]; then
        print_warning "No backups found in $BACKUP_DIR"
        return
    fi
    
    print_info "Backup files:"
    ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null | while read -r line; do
        echo "  $line"
    done
    
    echo ""
    print_info "Total backup size: $(du -sh "$BACKUP_DIR" | cut -f1)"
}

# Function to restore database
restore_database() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        print_error "Please specify backup file to restore"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        return 1
    fi
    
    print_header "Restoring database from: $backup_file"
    
    # Extract backup
    local temp_dir="/tmp/restore_$TIMESTAMP"
    mkdir -p "$temp_dir"
    
    print_info "Extracting backup..."
    if tar -xzf "$backup_file" -C "$temp_dir"; then
        # Find the database dump directory
        local dump_dir=$(find "$temp_dir" -name "hotel_mapping" -type d | head -1)
        
        if [ -z "$dump_dir" ]; then
            print_error "Could not find database dump in backup"
            rm -rf "$temp_dir"
            return 1
        fi
        
        # Copy dump to container
        print_info "Copying dump to container..."
        docker cp "$dump_dir" "$CONTAINER_MONGODB:/tmp/"
        
        # Restore database
        print_info "Restoring database..."
        if docker exec "$CONTAINER_MONGODB" mongorestore --drop "/tmp/hotel_mapping"; then
            print_success "Database restored successfully"
            
            # Cleanup
            docker exec "$CONTAINER_MONGODB" rm -rf "/tmp/hotel_mapping"
            rm -rf "$temp_dir"
            
            return 0
        else
            print_error "Failed to restore database"
            rm -rf "$temp_dir"
            return 1
        fi
    else
        print_error "Failed to extract backup"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Function to restore environment
restore_environment() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        print_error "Please specify environment backup file to restore"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        print_error "Environment backup file not found: $backup_file"
        return 1
    fi
    
    print_header "Restoring environment from: $backup_file"
    
    # Extract backup
    local temp_dir="/tmp/env_restore_$TIMESTAMP"
    mkdir -p "$temp_dir"
    
    if tar -xzf "$backup_file" -C "$temp_dir"; then
        # Find environment files and restore them
        find "$temp_dir" -name ".env*" -type f | while read -r env_file; do
            # Determine target location
            if [[ "$env_file" == *"/frontend/"* ]]; then
                target="frontend/$(basename "$env_file")"
            elif [[ "$env_file" == *"/backend/"* ]]; then
                target="backend/$(basename "$env_file")"
            else
                target="$(basename "$env_file")"
            fi
            
            print_info "Restoring $target"
            mkdir -p "$(dirname "$target")"
            cp "$env_file" "$target"
        done
        
        rm -rf "$temp_dir"
        print_success "Environment configuration restored"
    else
        print_error "Failed to extract environment backup"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Function to show backup info
show_backup_info() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        print_error "Please specify backup file"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        return 1
    fi
    
    print_header "Backup Information: $(basename "$backup_file")"
    
    # Extract and show metadata
    local temp_dir="/tmp/info_$TIMESTAMP"
    mkdir -p "$temp_dir"
    
    if tar -tzf "$backup_file" | grep -q "backup_info.json\|backup_manifest.json"; then
        tar -xzf "$backup_file" -C "$temp_dir"
        
        # Look for info files
        find "$temp_dir" -name "backup_info.json" -o -name "backup_manifest.json" | while read -r info_file; do
            echo ""
            print_info "$(basename "$info_file"):"
            cat "$info_file" | jq . 2>/dev/null || cat "$info_file"
        done
    else
        print_warning "No metadata found in backup file"
    fi
    
    rm -rf "$temp_dir"
    
    # Show file size and date
    echo ""
    print_info "File Details:"
    ls -lh "$backup_file"
}

# Function to cleanup old backups
cleanup_old_backups() {
    local days="${1:-7}" # Default: keep backups for 7 days
    
    print_header "Cleaning up backups older than $days days..."
    
    if [ ! -d "$BACKUP_DIR" ]; then
        print_warning "Backup directory does not exist"
        return
    fi
    
    # Find and remove old backups
    find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +$days -print0 | while IFS= read -r -d '' file; do
        print_info "Removing old backup: $(basename "$file")"
        rm "$file"
    done
    
    print_success "Cleanup completed"
}

# Main script
case "${1:-}" in
    "database")
        check_containers && backup_database
        ;;
    "environment"|"env")
        backup_environment
        ;;
    "application"|"app")
        backup_application
        ;;
    "complete"|"full")
        create_complete_backup
        ;;
    "list"|"ls")
        list_backups
        ;;
    "restore-db")
        restore_database "$2"
        ;;
    "restore-env")
        restore_environment "$2"
        ;;
    "info")
        show_backup_info "$2"
        ;;
    "cleanup")
        cleanup_old_backups "$2"
        ;;
    *)
        echo "Hotel Mapping Application - Backup & Restore System"
        echo ""
        echo "Usage: $0 [command] [options]"
        echo ""
        echo "Backup Commands:"
        echo "  database      Backup MongoDB database only"
        echo "  environment   Backup environment configuration files"
        echo "  application   Backup application source code"
        echo "  complete      Create complete system backup"
        echo ""
        echo "Management Commands:"
        echo "  list          List available backups"
        echo "  info <file>   Show backup information"
        echo "  cleanup [days] Clean up old backups (default: 7 days)"
        echo ""
        echo "Restore Commands:"
        echo "  restore-db <file>    Restore database from backup"
        echo "  restore-env <file>   Restore environment from backup"
        echo ""
        echo "Examples:"
        echo "  $0 complete                           # Create complete backup"
        echo "  $0 restore-db backups/mongodb_*.gz   # Restore database"
        echo "  $0 cleanup 30                        # Keep backups for 30 days"
        echo "  $0 info backups/complete_*.gz        # Show backup details"
        echo ""
        print_info "Backup directory: $BACKUP_DIR"
        print_info "Current timestamp: $TIMESTAMP"
        ;;
esac