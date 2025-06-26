#!/bin/bash
# ==============================================================================
# DiscoveryLastFM Docker Setup Script
# Automated setup for Docker environment
# ==============================================================================

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="${PROJECT_DIR}/../DiscoveryLastFM"

# Default settings
DEFAULT_MODE="interactive"
DEFAULT_PLATFORM="auto"
COMPOSE_PROFILE="default"

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

log_section() {
    echo ""
    echo -e "${PURPLE}=== $1 ===${NC}"
    echo ""
}

# Help function
show_help() {
    cat << EOF
DiscoveryLastFM Docker Setup Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -m, --mode MODE         Setup mode: interactive, automated, minimal (default: interactive)
    -p, --platform PLATFORM Target platform: auto, amd64, arm64 (default: auto)
    -c, --compose-profile   Docker Compose profile: default, dev, minimal (default: default)
    -s, --skip-source       Skip source code copying (for CI/testing)
    -d, --debug             Enable debug output
    --no-pull               Don't pull latest base images
    --no-build              Don't build images (use existing)

EXAMPLES:
    $0                          # Interactive setup
    $0 -m automated             # Automated setup with defaults
    $0 -m minimal -p arm64      # Minimal setup for ARM64
    $0 --compose-profile dev    # Development setup

PROFILES:
    default    - Full stack (DiscoveryLastFM + Lidarr + Redis)
    dev        - Development setup with debugging tools
    minimal    - DiscoveryLastFM only (no additional services)

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -m|--mode)
                DEFAULT_MODE="$2"
                shift 2
                ;;
            -p|--platform)
                DEFAULT_PLATFORM="$2"
                shift 2
                ;;
            -c|--compose-profile)
                COMPOSE_PROFILE="$2"
                shift 2
                ;;
            -s|--skip-source)
                SKIP_SOURCE=true
                shift
                ;;
            -d|--debug)
                DEBUG=true
                shift
                ;;
            --no-pull)
                NO_PULL=true
                shift
                ;;
            --no-build)
                NO_BUILD=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# System checks
check_requirements() {
    log_section "Checking Requirements"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running. Please start Docker first."
        exit 1
    fi
    
    # Check permissions
    if ! docker ps &> /dev/null; then
        log_warn "Current user cannot access Docker. You may need to add your user to the docker group:"
        log_warn "sudo usermod -aG docker \$USER"
        log_warn "Then log out and log back in."
    fi
    
    log_info "✅ All requirements met"
}

# Detect platform
detect_platform() {
    if [[ "$DEFAULT_PLATFORM" == "auto" ]]; then
        local arch
        arch=$(uname -m)
        case $arch in
            x86_64)
                DEFAULT_PLATFORM="amd64"
                ;;
            aarch64|arm64)
                DEFAULT_PLATFORM="arm64"
                ;;
            armv7l)
                DEFAULT_PLATFORM="arm/v7"
                ;;
            *)
                log_warn "Unknown architecture: $arch, defaulting to amd64"
                DEFAULT_PLATFORM="amd64"
                ;;
        esac
    fi
    
    log_info "Target platform: $DEFAULT_PLATFORM"
}

# Copy source files
copy_source_files() {
    if [[ "${SKIP_SOURCE:-false}" == "true" ]]; then
        log_info "Skipping source file copying"
        return 0
    fi
    
    log_section "Copying Source Files"
    
    if [[ ! -d "$SOURCE_DIR" ]]; then
        log_warn "Source directory not found: $SOURCE_DIR"
        log_warn "Creating placeholder files for build..."
        
        mkdir -p "$PROJECT_DIR/build-context"
        echo "# Placeholder DiscoveryLastFM.py" > "$PROJECT_DIR/build-context/DiscoveryLastFM.py"
        mkdir -p "$PROJECT_DIR/build-context/services" "$PROJECT_DIR/build-context/utils"
        echo "# Placeholder" > "$PROJECT_DIR/build-context/services/__init__.py"
        echo "# Placeholder" > "$PROJECT_DIR/build-context/utils/__init__.py"
        
        return 0
    fi
    
    log_info "Copying source files from $SOURCE_DIR"
    
    # Create build context
    mkdir -p "$PROJECT_DIR/build-context"
    
    # Copy main script
    if [[ -f "$SOURCE_DIR/DiscoveryLastFM.py" ]]; then
        cp "$SOURCE_DIR/DiscoveryLastFM.py" "$PROJECT_DIR/build-context/"
        log_info "✅ Copied DiscoveryLastFM.py"
    else
        log_error "Main script not found: $SOURCE_DIR/DiscoveryLastFM.py"
        exit 1
    fi
    
    # Copy services directory
    if [[ -d "$SOURCE_DIR/services" ]]; then
        cp -r "$SOURCE_DIR/services" "$PROJECT_DIR/build-context/"
        log_info "✅ Copied services directory"
    else
        log_warn "Services directory not found, creating empty one"
        mkdir -p "$PROJECT_DIR/build-context/services"
        echo "# Placeholder services module" > "$PROJECT_DIR/build-context/services/__init__.py"
    fi
    
    # Copy utils directory
    if [[ -d "$SOURCE_DIR/utils" ]]; then
        cp -r "$SOURCE_DIR/utils" "$PROJECT_DIR/build-context/"
        log_info "✅ Copied utils directory"
    else
        log_warn "Utils directory not found, creating empty one"
        mkdir -p "$PROJECT_DIR/build-context/utils"
        echo "# Placeholder utils module" > "$PROJECT_DIR/build-context/utils/__init__.py"
    fi
}

# Interactive configuration
interactive_config() {
    if [[ "$DEFAULT_MODE" != "interactive" ]]; then
        return 0
    fi
    
    log_section "Interactive Configuration"
    
    echo "Welcome to DiscoveryLastFM Docker Setup!"
    echo ""
    echo "This script will help you set up DiscoveryLastFM in Docker."
    echo ""
    
    # Environment file setup
    if [[ ! -f "$PROJECT_DIR/.env" ]]; then
        log_info "Setting up environment configuration..."
        
        if [[ -f "$PROJECT_DIR/.env.example" ]]; then
            cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
            log_info "✅ Created .env from .env.example"
            log_warn "⚠️  Please edit .env file with your actual configuration"
        else
            log_error ".env.example not found"
            exit 1
        fi
    else
        log_info "Environment file already exists: .env"
    fi
    
    # Ask for basic configuration
    echo ""
    read -p "Enter your Last.fm username: " lastfm_user
    if [[ -n "$lastfm_user" ]]; then
        sed -i "s/LASTFM_USERNAME=.*/LASTFM_USERNAME=$lastfm_user/" "$PROJECT_DIR/.env"
    fi
    
    read -p "Enter your Last.fm API key: " lastfm_key
    if [[ -n "$lastfm_key" ]]; then
        sed -i "s/LASTFM_API_KEY=.*/LASTFM_API_KEY=$lastfm_key/" "$PROJECT_DIR/.env"
    fi
    
    echo ""
    echo "Which music service do you want to use?"
    echo "1) Lidarr (recommended)"
    echo "2) Headphones"
    read -p "Choice [1]: " music_service_choice
    
    case "${music_service_choice:-1}" in
        1)
            sed -i "s/MUSIC_SERVICE=.*/MUSIC_SERVICE=lidarr/" "$PROJECT_DIR/.env"
            echo ""
            read -p "Enter your Lidarr API key: " lidarr_key
            if [[ -n "$lidarr_key" ]]; then
                sed -i "s/LIDARR_API_KEY=.*/LIDARR_API_KEY=$lidarr_key/" "$PROJECT_DIR/.env"
            fi
            ;;
        2)
            sed -i "s/MUSIC_SERVICE=.*/MUSIC_SERVICE=headphones/" "$PROJECT_DIR/.env"
            echo ""
            read -p "Enter your Headphones API key: " hp_key
            if [[ -n "$hp_key" ]]; then
                sed -i "s/HP_API_KEY=.*/HP_API_KEY=$hp_key/" "$PROJECT_DIR/.env"
            fi
            ;;
    esac
    
    log_info "✅ Basic configuration completed"
}

# Build Docker images
build_images() {
    if [[ "${NO_BUILD:-true}" == "true" ]]; then
        log_info "Skipping image build"
        return 0
    fi
    
    log_section "Building Docker Images"
    
    cd "$PROJECT_DIR"
    
    # Pull base images
    if [[ "${NO_PULL:-true}" != "true" ]]; then
        log_info "Pulling latest base images..."
        docker pull python:3.11-slim
    fi
    
    # Build main image
    log_info "Building DiscoveryLastFM image..."
    docker build \
        --platform "linux/$DEFAULT_PLATFORM" \
        --tag "mrrobotogit/discoverylastfm:latest" \
        --tag "mrrobotogit/discoverylastfm:local" \
        .
    
    log_info "✅ Docker image built successfully"
}

# Setup Docker Compose
setup_compose() {
    log_section "Setting up Docker Compose"
    
    cd "$PROJECT_DIR"
    
    # Choose compose file based on profile
    local compose_files=("-f" "docker-compose.yml")
    
    case "$COMPOSE_PROFILE" in
        dev)
            compose_files+=("-f" "docker-compose.dev.yml")
            log_info "Using development profile"
            ;;
        minimal)
            # Create minimal compose file
            cat > docker-compose.minimal.yml << 'EOF'
version: '3.8'

services:
  discoverylastfm:
    extends:
      file: docker-compose.yml
      service: discoverylastfm
    depends_on: []
    ports:
      - "8080:8080"
EOF
            compose_files=("-f" "docker-compose.minimal.yml")
            log_info "Using minimal profile (DiscoveryLastFM only)"
            ;;
        default)
            log_info "Using default profile (full stack)"
            ;;
    esac
    
    # Validate compose files
    log_info "Validating Docker Compose configuration..."
    if docker-compose "${compose_files[@]}" config --quiet; then
        log_info "✅ Docker Compose configuration is valid"
    else
        log_error "Docker Compose configuration is invalid"
        exit 1
    fi
    
    # Store compose command for later use
    echo "docker-compose ${compose_files[*]}" > .compose-command
}

# Start services
start_services() {
    log_section "Starting Services"
    
    cd "$PROJECT_DIR"
    
    # Read compose command
    local compose_cmd
    if [[ -f ".compose-command" ]]; then
        compose_cmd=$(cat .compose-command)
    else
        compose_cmd="docker-compose"
    fi
    
    log_info "Starting services with: $compose_cmd"
    
    # Start services
    if $compose_cmd up -d; then
        log_info "✅ Services started successfully"
    else
        log_error "Failed to start services"
        exit 1
    fi
    
    # Wait for health checks
    log_info "Waiting for services to be healthy..."
    local timeout=60
    local elapsed=0
    
    while [[ $elapsed -lt $timeout ]]; do
        local healthy_count
        healthy_count=$($compose_cmd ps --format json 2>/dev/null | jq -r '.Health // "unknown"' | grep -c "healthy" || echo "0")
        
        if [[ $healthy_count -gt 0 ]]; then
            log_info "✅ Services are healthy"
            break
        fi
        
        sleep 2
        elapsed=$((elapsed + 2))
        echo -n "."
    done
    
    echo ""
    
    if [[ $elapsed -ge $timeout ]]; then
        log_warn "Timeout waiting for services to be healthy"
        log_info "You can check status with: $compose_cmd ps"
    fi
}

# Show status and next steps
show_status() {
    log_section "Setup Complete"
    
    cd "$PROJECT_DIR"
    
    # Read compose command
    local compose_cmd
    if [[ -f ".compose-command" ]]; then
        compose_cmd=$(cat .compose-command)
    else
        compose_cmd="docker-compose"
    fi
    
    echo "🎉 DiscoveryLastFM Docker setup completed successfully!"
    echo ""
    echo "📋 Service Status:"
    $compose_cmd ps
    echo ""
    echo "🔧 Useful Commands:"
    echo "  View logs:           $compose_cmd logs -f"
    echo "  Stop services:       $compose_cmd down"
    echo "  Restart services:    $compose_cmd restart"
    echo "  Update images:       $compose_cmd pull && $compose_cmd up -d"
    echo ""
    echo "📖 Next Steps:"
    echo "  1. Edit .env file with your actual credentials"
    echo "  2. Restart services: $compose_cmd restart"
    echo "  3. Check logs: $compose_cmd logs -f discoverylastfm"
    echo ""
    
    # Show service URLs if applicable
    if [[ "$COMPOSE_PROFILE" != "minimal" ]]; then
        echo "🌐 Service URLs:"
        echo "  Lidarr:     http://localhost:8686"
        echo "  Portainer:  http://localhost:9000 (if enabled)"
        echo ""
    fi
    
    echo "📚 Documentation: https://github.com/MrRobotoGit/DiscoveryLastFM-Docker"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up temporary files..."
    rm -f "$PROJECT_DIR/.compose-command"
}

# Main execution
main() {
    log_info "DiscoveryLastFM Docker Setup Script v1.0"
    
    # Parse arguments
    parse_args "$@"
    
    # Set trap for cleanup
    trap cleanup EXIT
    
    # Execute setup steps
    check_requirements
    detect_platform
    copy_source_files
    interactive_config
    build_images
    setup_compose
    start_services
    show_status
    
    log_info "Setup completed successfully! 🎉"
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi