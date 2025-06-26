#!/bin/bash
# ==============================================================================
# DiscoveryLastFM Docker Entrypoint Script
# Handles container initialization, configuration, and startup modes
# ==============================================================================

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Default paths
CONFIG_PATH="${CONFIG_PATH:-/app/config/config.py}"
CONFIG_EXAMPLE_PATH="/app/config.example.py"
LOG_PATH="${LOG_PATH:-/app/logs}"
CACHE_PATH="${CACHE_PATH:-/app/cache}"

# Environment variables with defaults
DISCOVERY_MODE="${DISCOVERY_MODE:-sync}"
CRON_SCHEDULE="${CRON_SCHEDULE:-0 3 * * *}"
DRY_RUN="${DRY_RUN:-false}"
DEBUG="${DEBUG:-false}"

# ==============================================================================
# Configuration Management
# ==============================================================================

setup_configuration() {
    log_info "Setting up configuration..."
    
    # Ensure config directory exists
    mkdir -p "$(dirname "$CONFIG_PATH")"
    
    # Check if config file exists
    if [[ ! -f "$CONFIG_PATH" ]]; then
        log_warn "Configuration file not found at $CONFIG_PATH"
        
        # Check for environment variables configuration
        if [[ -n "${LASTFM_USERNAME:-}" && -n "${LASTFM_API_KEY:-}" && -n "${MUSIC_SERVICE:-}" ]]; then
            log_info "Creating configuration from environment variables..."
            create_config_from_env
        else
            log_warn "No environment variables found for configuration"
            
            # Copy example configuration
            if [[ -f "$CONFIG_EXAMPLE_PATH" ]]; then
                log_info "Copying example configuration to $CONFIG_PATH"
                cp "$CONFIG_EXAMPLE_PATH" "$CONFIG_PATH"
                log_warn "Please edit $CONFIG_PATH with your credentials before running"
            else
                log_error "No example configuration found at $CONFIG_EXAMPLE_PATH"
                exit 1
            fi
        fi
    else
        log_info "Configuration file found at $CONFIG_PATH"
    fi
    
    # Validate configuration exists and is readable
    if [[ ! -r "$CONFIG_PATH" ]]; then
        log_error "Configuration file is not readable: $CONFIG_PATH"
        exit 1
    fi
}

create_config_from_env() {
    cat > "$CONFIG_PATH" << EOF
# DiscoveryLastFM Configuration - Generated from Environment Variables
# Generated at: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

# === MUSIC SERVICE SELECTION ===
MUSIC_SERVICE = "${MUSIC_SERVICE:-headphones}"

# === LAST.FM CONFIGURATION ===
LASTFM_USERNAME = "${LASTFM_USERNAME}"
LASTFM_API_KEY = "${LASTFM_API_KEY}"

# === HEADPHONES CONFIGURATION ===
$(if [[ "${MUSIC_SERVICE:-headphones}" == "headphones" ]]; then
cat << 'HPEOF'
HP_API_KEY = "${HP_API_KEY:-}"
HP_ENDPOINT = "${HP_ENDPOINT:-http://headphones:8181}"
HP_MAX_RETRIES = ${HP_MAX_RETRIES:-3}
HP_RETRY_DELAY = ${HP_RETRY_DELAY:-5}
HP_TIMEOUT = ${HP_TIMEOUT:-60}
HPEOF
fi)

# === LIDARR CONFIGURATION ===
$(if [[ "${MUSIC_SERVICE:-}" == "lidarr" ]]; then
cat << 'LIDARREOF'
LIDARR_API_KEY = "${LIDARR_API_KEY:-}"
LIDARR_ENDPOINT = "${LIDARR_ENDPOINT:-http://lidarr:8686}"
LIDARR_ROOT_FOLDER = "${LIDARR_ROOT_FOLDER:-/music}"
LIDARR_QUALITY_PROFILE_ID = ${LIDARR_QUALITY_PROFILE_ID:-1}
LIDARR_METADATA_PROFILE_ID = ${LIDARR_METADATA_PROFILE_ID:-1}
LIDARR_MONITOR_MODE = "${LIDARR_MONITOR_MODE:-all}"
LIDARR_SEARCH_ON_ADD = ${LIDARR_SEARCH_ON_ADD:-True}
LIDARR_MAX_RETRIES = ${LIDARR_MAX_RETRIES:-3}
LIDARR_RETRY_DELAY = ${LIDARR_RETRY_DELAY:-5}
LIDARR_TIMEOUT = ${LIDARR_TIMEOUT:-60}
LIDARREOF
fi)

# === DISCOVERY PARAMETERS ===
RECENT_MONTHS = ${RECENT_MONTHS:-3}
MIN_PLAYS = ${MIN_PLAYS:-20}
SIMILAR_MATCH_MIN = ${SIMILAR_MATCH_MIN:-0.46}
MAX_SIMILAR_PER_ART = ${MAX_SIMILAR_PER_ART:-20}
MAX_POP_ALBUMS = ${MAX_POP_ALBUMS:-5}
CACHE_TTL_HOURS = ${CACHE_TTL_HOURS:-24}

# === API RATE LIMITING ===
REQUEST_LIMIT = ${REQUEST_LIMIT:-0.2}
MBZ_DELAY = ${MBZ_DELAY:-1.1}

# === DEBUGGING ===
DEBUG_PRINT = ${DEBUG_PRINT:-False}

# === AUTO-UPDATE SYSTEM (v2.1.0+) ===
AUTO_UPDATE_ENABLED = ${AUTO_UPDATE_ENABLED:-False}
UPDATE_CHECK_INTERVAL_HOURS = ${UPDATE_CHECK_INTERVAL_HOURS:-24}
BACKUP_RETENTION_DAYS = ${BACKUP_RETENTION_DAYS:-7}
ALLOW_PRERELEASE_UPDATES = ${ALLOW_PRERELEASE_UPDATES:-False}
GITHUB_TOKEN = "${GITHUB_TOKEN:-}"
GITHUB_REPO_OWNER = "MrRobotoGit"
GITHUB_REPO_NAME = "DiscoveryLastFM"
EOF
    
    log_info "Configuration created from environment variables"
}

# ==============================================================================
# Logging Setup
# ==============================================================================

setup_logging() {
    log_info "Setting up logging directory..."
    
    # Create logs directory if it doesn't exist
    mkdir -p "$LOG_PATH"
    
    # Set proper permissions
    chmod 755 "$LOG_PATH"
    
    log_debug "Log directory ready at $LOG_PATH"
}

# ==============================================================================
# Cache Setup
# ==============================================================================

setup_cache() {
    log_info "Setting up cache directory..."
    
    # Create cache directory if it doesn't exist
    mkdir -p "$CACHE_PATH"
    
    # Set proper permissions
    chmod 755 "$CACHE_PATH"
    
    log_debug "Cache directory ready at $CACHE_PATH"
}

# ==============================================================================
# Cron Setup (for scheduled mode)
# ==============================================================================

setup_cron() {
    log_info "Setting up cron for scheduled execution..."
    
    # Create cron job
    echo "$CRON_SCHEDULE cd /app && python DiscoveryLastFM.py >> $LOG_PATH/cron.log 2>&1" | crontab -
    
    log_info "Cron job scheduled: $CRON_SCHEDULE"
    
    # Start cron daemon
    log_info "Starting cron daemon..."
    cron
}

# ==============================================================================
# Health Check
# ==============================================================================

health_check() {
    log_info "Performing health check..."
    
    # Check configuration
    if ! python -c "exec(open('$CONFIG_PATH').read()); print('Config OK')" >/dev/null 2>&1; then
        log_error "Configuration validation failed"
        return 1
    fi
    
    # Check if DiscoveryLastFM.py exists and is executable
    if [[ ! -f "/app/DiscoveryLastFM.py" ]]; then
        log_error "DiscoveryLastFM.py not found"
        return 1
    fi
    
    log_info "Health check passed"
    return 0
}

# ==============================================================================
# Signal Handlers
# ==============================================================================

cleanup() {
    log_info "Received shutdown signal, cleaning up..."
    
    # Kill background processes
    jobs -p | xargs -r kill
    
    # Stop cron if running
    pkill -f cron || true
    
    log_info "Cleanup completed"
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# ==============================================================================
# Main Execution Logic
# ==============================================================================

main() {
    log_info "Starting DiscoveryLastFM Container..."
    log_info "Mode: $DISCOVERY_MODE"
    log_info "Debug: $DEBUG"
    
    # Setup steps
    setup_configuration
    setup_logging
    setup_cache
    
    # Health check
    if ! health_check; then
        log_error "Health check failed, exiting"
        exit 1
    fi
    
    # Change to app directory
    cd /app
    
    # Handle v2.1.0 CLI commands first
    if [[ "$1" == "--update" || "$1" == "--update-status" || "$1" == "--list-backups" || "$1" == "--version" || "$1" == "--cleanup" ]]; then
        log_info "Executing DiscoveryLastFM CLI command: $1"
        exec python DiscoveryLastFM.py "$@"
    fi
    
    case "$DISCOVERY_MODE" in
        "sync")
            log_info "Running one-time sync..."
            if [[ "$DRY_RUN" == "true" ]]; then
                log_info "DRY RUN MODE - No actual changes will be made"
                export DRY_RUN=true
            fi
            exec "$@"
            ;;
            
        "cron")
            log_info "Setting up scheduled execution..."
            setup_cron
            log_info "Container will run scheduled jobs. Keeping container alive..."
            # Keep container running for cron jobs
            while true; do
                sleep 60
            done
            ;;
            
        "daemon")
            log_info "Running in daemon mode..."
            while true; do
                log_info "Running scheduled discovery..."
                if [[ "$DRY_RUN" == "true" ]]; then
                    log_info "DRY RUN MODE - No actual changes will be made"
                    export DRY_RUN=true
                fi
                python DiscoveryLastFM.py >> "$LOG_PATH/daemon.log" 2>&1 || log_error "Discovery run failed"
                
                # Calculate sleep time (default 3 hours)
                SLEEP_HOURS=${SLEEP_HOURS:-3}
                SLEEP_SECONDS=$((SLEEP_HOURS * 3600))
                log_info "Sleeping for $SLEEP_HOURS hours..."
                sleep $SLEEP_SECONDS
            done
            ;;
            
        "test")
            log_info "Running in test mode..."
            python -c "
import sys
sys.path.append('/app')
try:
    exec(open('$CONFIG_PATH').read())
    print('✅ Configuration loaded successfully')
    
    # Test imports
    from services.factory import MusicServiceFactory
    print('✅ Service factory imported successfully')
    
    # Test service creation (dry run)
    config_dict = {k: v for k, v in globals().items() if k.isupper()}
    service_type = config_dict.get('MUSIC_SERVICE', 'headphones')
    print(f'✅ Service type: {service_type}')
    
    print('✅ Test mode completed successfully')
except Exception as e:
    print(f'❌ Test failed: {e}')
    sys.exit(1)
"
            ;;
            
        *)
            log_error "Unknown mode: $DISCOVERY_MODE"
            log_info "Available modes: sync, cron, daemon, test"
            exit 1
            ;;
    esac
}

# ==============================================================================
# Script Entry Point
# ==============================================================================

# Ensure we're running as the correct user
if [[ "$(id -u)" -eq 0 ]]; then
    log_warn "Running as root, this is not recommended for security"
fi

# Run main function with all arguments
main "$@"