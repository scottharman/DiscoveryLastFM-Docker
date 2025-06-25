#!/bin/bash
# ==============================================================================
# DiscoveryLastFM Multi-Architecture Build Script
# Build Docker images for multiple platforms (AMD64 + ARM64)
# ==============================================================================

set -euo pipefail

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="${PROJECT_DIR}/../DiscoveryLastFM"

# Default settings
PLATFORMS="linux/amd64,linux/arm64"
IMAGE_NAME="mrrobotogit/discoverylastfm"
PUSH_TO_REGISTRY=false
BUILD_CACHE=true
BUILDX_BUILDER="discoverylastfm-builder"

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_debug() { [[ "${DEBUG:-false}" == "true" ]] && echo -e "${BLUE}[DEBUG]${NC} $1" || true; }

# Help function
show_help() {
    cat << EOF
DiscoveryLastFM Multi-Architecture Build Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -p, --platforms LIST    Comma-separated list of platforms (default: linux/amd64,linux/arm64)
    -t, --tag TAG           Image tag (default: latest)
    -n, --name NAME         Image name (default: mrrobotogit/discoverylastfm)
    --push                  Push to registry after build
    --no-cache              Disable build cache
    --load                  Load image to local Docker (single platform only)
    -d, --debug             Enable debug output

EXAMPLES:
    $0                              # Build for AMD64 + ARM64
    $0 --platforms linux/amd64     # Build for AMD64 only
    $0 --push --tag v2.1.0          # Build and push with version tag
    $0 --load --platforms linux/amd64  # Build and load locally (AMD64 only)

PLATFORMS:
    linux/amd64     - Intel/AMD 64-bit
    linux/arm64     - ARM 64-bit (Raspberry Pi 4+)
    linux/arm/v7    - ARM 32-bit (Raspberry Pi 3)

EOF
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -p|--platforms)
                PLATFORMS="$2"
                shift 2
                ;;
            -t|--tag)
                TAG="$2"
                shift 2
                ;;
            -n|--name)
                IMAGE_NAME="$2"
                shift 2
                ;;
            --push)
                PUSH_TO_REGISTRY=true
                shift
                ;;
            --no-cache)
                BUILD_CACHE=false
                shift
                ;;
            --load)
                LOAD_IMAGE=true
                shift
                ;;
            -d|--debug)
                DEBUG=true
                export BUILDKIT_PROGRESS=plain
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Set default tag if not provided
    TAG="${TAG:-latest}"
    
    # Validate load option
    if [[ "${LOAD_IMAGE:-false}" == "true" && "$PLATFORMS" == *","* ]]; then
        log_error "Cannot load multi-platform builds. Use single platform with --load"
        exit 1
    fi
    
    # Cannot push and load at the same time
    if [[ "$PUSH_TO_REGISTRY" == "true" && "${LOAD_IMAGE:-false}" == "true" ]]; then
        log_error "Cannot use --push and --load together"
        exit 1
    fi
}

# Check requirements
check_requirements() {
    log_info "Checking build requirements..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    # Check Docker buildx
    if ! docker buildx version &> /dev/null; then
        log_error "Docker buildx is not available"
        exit 1
    fi
    
    # Check for experimental mode (required for multi-arch)
    if ! docker buildx ls &> /dev/null; then
        log_error "Docker buildx is not properly configured"
        exit 1
    fi
    
    log_info "✅ All requirements met"
}

# Setup buildx builder
setup_builder() {
    log_info "Setting up multi-architecture builder..."
    
    # Check if builder exists
    if docker buildx inspect "$BUILDX_BUILDER" &> /dev/null; then
        log_info "Builder '$BUILDX_BUILDER' already exists"
    else
        log_info "Creating new builder: $BUILDX_BUILDER"
        docker buildx create \
            --name "$BUILDX_BUILDER" \
            --driver docker-container \
            --platform "$PLATFORMS" \
            --use
    fi
    
    # Use the builder
    docker buildx use "$BUILDX_BUILDER"
    
    # Bootstrap the builder
    log_info "Bootstrapping builder..."
    docker buildx inspect --bootstrap
    
    log_info "✅ Builder ready"
}

# Prepare build context
prepare_build_context() {
    log_info "Preparing build context..."
    
    cd "$PROJECT_DIR"
    
    # Create build context
    mkdir -p build-context
    
    if [[ -d "$SOURCE_DIR" ]]; then
        log_info "Copying source files from $SOURCE_DIR"
        
        # Copy main script
        if [[ -f "$SOURCE_DIR/DiscoveryLastFM.py" ]]; then
            cp "$SOURCE_DIR/DiscoveryLastFM.py" build-context/
            log_debug "Copied DiscoveryLastFM.py"
        else
            log_error "Main script not found: $SOURCE_DIR/DiscoveryLastFM.py"
            exit 1
        fi
        
        # Copy services directory
        if [[ -d "$SOURCE_DIR/services" ]]; then
            cp -r "$SOURCE_DIR/services" build-context/
            log_debug "Copied services directory"
        else
            log_warn "Services directory not found, creating placeholder"
            mkdir -p build-context/services
            echo "# Placeholder" > build-context/services/__init__.py
        fi
        
        # Copy utils directory
        if [[ -d "$SOURCE_DIR/utils" ]]; then
            cp -r "$SOURCE_DIR/utils" build-context/
            log_debug "Copied utils directory"
        else
            log_warn "Utils directory not found, creating placeholder"
            mkdir -p build-context/utils
            echo "# Placeholder" > build-context/utils/__init__.py
        fi
    else
        log_warn "Source directory not found: $SOURCE_DIR"
        log_warn "Creating placeholder files for build"
        
        echo "# Placeholder DiscoveryLastFM.py" > build-context/DiscoveryLastFM.py
        mkdir -p build-context/{services,utils}
        echo "# Placeholder" > build-context/services/__init__.py
        echo "# Placeholder" > build-context/utils/__init__.py
    fi
    
    log_info "✅ Build context prepared"
}

# Build multi-architecture image
build_image() {
    log_info "Building multi-architecture Docker image..."
    log_info "Platforms: $PLATFORMS"
    log_info "Image: $IMAGE_NAME:$TAG"
    
    cd "$PROJECT_DIR"
    
    # Build arguments
    local build_args=(
        "buildx" "build"
        "--platform" "$PLATFORMS"
        "--tag" "$IMAGE_NAME:$TAG"
        "--file" "Dockerfile"
    )
    
    # Cache options
    if [[ "$BUILD_CACHE" == "true" ]]; then
        build_args+=(
            "--cache-from" "type=gha,scope=buildx-$BUILDX_BUILDER"
            "--cache-to" "type=gha,mode=max,scope=buildx-$BUILDX_BUILDER"
        )
    else
        build_args+=("--no-cache")
    fi
    
    # Output options
    if [[ "$PUSH_TO_REGISTRY" == "true" ]]; then
        build_args+=("--push")
        log_info "Will push to registry after build"
    elif [[ "${LOAD_IMAGE:-false}" == "true" ]]; then
        build_args+=("--load")
        log_info "Will load image locally after build"
    else
        log_info "Build only (no push or load)"
    fi
    
    # Build context
    build_args+=(".")
    
    # Execute build
    log_info "Executing: docker ${build_args[*]}"
    
    if docker "${build_args[@]}"; then
        log_info "✅ Multi-architecture build completed successfully"
    else
        log_error "Build failed"
        exit 1
    fi
}

# Verify build
verify_build() {
    if [[ "$PUSH_TO_REGISTRY" == "true" ]]; then
        log_info "Verifying pushed images..."
        
        # Split platforms and test each
        IFS=',' read -ra PLATFORM_ARRAY <<< "$PLATFORMS"
        for platform in "${PLATFORM_ARRAY[@]}"; do
            log_info "Testing $platform image..."
            
            if docker run --rm --platform="$platform" "$IMAGE_NAME:$TAG" \
                python -c "print('✅ $platform image works')"; then
                log_info "✅ $platform image verified"
            else
                log_error "❌ $platform image verification failed"
                exit 1
            fi
        done
    elif [[ "${LOAD_IMAGE:-false}" == "true" ]]; then
        log_info "Verifying loaded image..."
        
        if docker run --rm "$IMAGE_NAME:$TAG" \
            python -c "print('✅ Loaded image works')"; then
            log_info "✅ Loaded image verified"
        else
            log_error "❌ Loaded image verification failed"
            exit 1
        fi
    else
        log_info "Build verification skipped (not pushed or loaded)"
    fi
}

# Show build summary
show_summary() {
    log_info "Build Summary:"
    echo "  Image:      $IMAGE_NAME:$TAG"
    echo "  Platforms:  $PLATFORMS"
    echo "  Pushed:     $PUSH_TO_REGISTRY"
    echo "  Loaded:     ${LOAD_IMAGE:-false}"
    echo "  Cache:      $BUILD_CACHE"
    
    if [[ "$PUSH_TO_REGISTRY" == "true" ]]; then
        echo ""
        echo "🐳 Pull commands:"
        IFS=',' read -ra PLATFORM_ARRAY <<< "$PLATFORMS"
        for platform in "${PLATFORM_ARRAY[@]}"; do
            echo "  docker pull --platform=$platform $IMAGE_NAME:$TAG"
        done
    fi
    
    if [[ "${LOAD_IMAGE:-false}" == "true" ]]; then
        echo ""
        echo "🚀 Run command:"
        echo "  docker run --rm $IMAGE_NAME:$TAG"
    fi
}

# Cleanup function
cleanup() {
    log_info "Cleaning up..."
    rm -rf "$PROJECT_DIR/build-context"
    
    # Optionally remove builder (uncomment if needed)
    # docker buildx rm "$BUILDX_BUILDER" || true
}

# Main execution
main() {
    log_info "DiscoveryLastFM Multi-Architecture Build Script"
    
    # Parse arguments
    parse_args "$@"
    
    # Set cleanup trap
    trap cleanup EXIT
    
    # Execute build pipeline
    check_requirements
    setup_builder
    prepare_build_context
    build_image
    verify_build
    show_summary
    
    log_info "Multi-architecture build completed successfully! 🎉"
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi