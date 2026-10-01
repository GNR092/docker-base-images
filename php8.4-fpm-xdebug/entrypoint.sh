#!/bin/sh
# =============================================================================
# Entrypoint Script for PHP 8.4-FPM with Xdebug
# =============================================================================
# This script:
# 1. Substitutes environment variables in configuration files
# 2. Creates necessary directories and sets permissions
# 3. Handles Xdebug runtime configuration
# 4. Starts PHP-FPM
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# Environment Variable Substitution
# =============================================================================

substitute_env_vars() {
    local file="$1"
    if [ -f "$file" ]; then
        log_info "Substituting environment variables in $file"
        # Use envsubst to replace ${VAR} patterns
        # Only substitute known variables to avoid issues
        envsubst \
            '${PHP_FPM_LISTEN} \
            ${PHP_FPM_PM} \
            ${PHP_FPM_PM_MAX_CHILDREN} \
            ${PHP_FPM_PM_START_SERVERS} \
            ${PHP_FPM_PM_MIN_SPARE_SERVERS} \
            ${PHP_FPM_PM_MAX_SPARE_SERVERS} \
            ${PHP_MEMORY_LIMIT} \
            ${PHP_MAX_EXECUTION_TIME} \
            ${PHP_UPLOAD_MAX_FILESIZE} \
            ${PHP_POST_MAX_SIZE} \
            ${PHP_DATE_TIMEZONE} \
            ${XDEBUG_MODE} \
            ${XDEBUG_CLIENT_HOST} \
            ${XDEBUG_CLIENT_PORT} \
            ${XDEBUG_START_WITH_REQUEST} \
            ${XDEBUG_DISCOVER_CLIENT_HOST} \
            ${XDEBUG_IDE_KEY} \
            ${XDEBUG_LOG} \
            ${XDEBUG_LOG_LEVEL} \
            ${XDEBUG_MAX_NESTING_LEVEL} \
            ${XDEBUG_MAX_STACK_FRAMES} \
            ${XDEBUG_SHOW_ERROR_TRACE} \
            ${XDEBUG_SHOW_EXCEPTION_TRACE} \
            ${XDEBUG_SHOW_LOCAL_VARS} \
            ${OPCACHE_ENABLE} \
            ${OPCACHE_ENABLE_CLI} \
            ${OPCACHE_MEMORY_CONSUMPTION} \
            ${OPCACHE_INTERNED_STRINGS_BUFFER} \
            ${OPCACHE_MAX_ACCELERATED_FILES} \
            ${OPCACHE_REVALIDATE_FREQ} \
            ${OPCACHE_FAST_SHUTDOWN} \
            ${OPCACHE_VALIDATE_TIMESTAMPS}' \
            < "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    fi
}

# Substitute variables in all config files
log_info "Processing configuration files..."

for config_file in \
    /usr/local/etc/php-fpm.d/www.conf \
    /usr/local/etc/php/conf.d/docker-php.ini \
    /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    /usr/local/etc/php/conf.d/opcache.ini; do
    substitute_env_vars "$config_file"
done

# =============================================================================
# Directory and Permission Setup
# =============================================================================

log_info "Setting up directories and permissions..."

# Create log directories
mkdir -p /var/log/php-fpm
mkdir -p /var/lib/php/sessions

# Set ownership
chown -R www-data:www-data /var/log/php-fpm
chown -R www-data:www-data /var/lib/php/sessions
chown -R www-data:www-data /var/www/html

# Set permissions
chmod 775 /var/log/php-fpm
chmod 775 /var/lib/php/sessions
chmod -R 775 /var/www/html

# =============================================================================
# Xdebug Runtime Configuration
# =============================================================================

configure_xdebug() {
    log_info "Configuring Xdebug (mode: ${XDEBUG_MODE})..."

    # If Xdebug is disabled, we can skip further config
    if [ "${XDEBUG_MODE}" = "off" ]; then
        log_info "Xdebug is disabled (XDEBUG_MODE=off)"
        return 0
    fi

    # Create Xdebug log file if it doesn't exist
    if [ -n "${XDEBUG_LOG}" ] && [ "${XDEBUG_LOG}" != "" ]; then
        touch "${XDEBUG_LOG}" 2>/dev/null || true
        chown www-data:www-data "${XDEBUG_LOG}" 2>/dev/null || true
        chmod 664 "${XDEBUG_LOG}" 2>/dev/null || true
        log_info "Xdebug log file: ${XDEBUG_LOG}"
    fi

    # Validate client host for debugging
    if [ "${XDEBUG_MODE}" = "debug" ] || echo "${XDEBUG_MODE}" | grep -q "debug"; then
        if [ "${XDEBUG_CLIENT_HOST}" = "host.docker.internal" ]; then
            log_warning "Using host.docker.internal for XDEBUG_CLIENT_HOST."
            log_warning "On Linux, ensure you use --add-host=host.docker.internal:host-gateway"
            log_warning "Or set XDEBUG_CLIENT_HOST to your host IP address."
        fi
        log_info "Xdebug step debugging enabled - IDE should listen on ${XDEBUG_CLIENT_HOST}:${XDEBUG_CLIENT_PORT}"
    fi

    log_success "Xdebug configuration complete"
}

configure_xdebug

# =============================================================================
# OPcache Validation
# =============================================================================

log_info "Validating OPcache configuration..."
if [ "${OPCACHE_VALIDATE_TIMESTAMPS}" = "1" ] && [ "${APP_ENV}" = "production" ]; then
    log_warning "OPcache validate_timestamps=1 in production. Consider setting OPCACHE_VALIDATE_TIMESTAMPS=0 for production deployments."
fi

# =============================================================================
# PHP-FPM Configuration Test
# =============================================================================

log_info "Testing PHP-FPM configuration..."
if php-fpm -t; then
    log_success "PHP-FPM configuration test passed"
else
    log_error "PHP-FPM configuration test failed"
    exit 1
fi

# =============================================================================
# Display Startup Information
# =============================================================================

log_info "=========================================="
log_info "PHP 8.4-FPM with Xdebug Starting"
log_info "=========================================="
log_info "PHP Version: $(php -v | head -n1)"
log_info "PHP-FPM Listen: ${PHP_FPM_LISTEN}"
log_info "Process Manager: ${PHP_FPM_PM}"
log_info "Max Children: ${PHP_FPM_PM_MAX_CHILDREN}"
log_info "Memory Limit: ${PHP_MEMORY_LIMIT}"
log_info "Max Execution Time: ${PHP_MAX_EXECUTION_TIME}s"
log_info "Timezone: ${PHP_DATE_TIMEZONE}"
log_info "App Environment: ${APP_ENV}"
log_info "Xdebug Mode: ${XDEBUG_MODE}"
if [ "${XDEBUG_MODE}" != "off" ]; then
    log_info "Xdebug Client: ${XDEBUG_CLIENT_HOST}:${XDEBUG_CLIENT_PORT}"
    log_info "Xdebug IDE Key: ${XDEBUG_IDE_KEY}"
fi
log_info "OPcache Enabled: ${OPCACHE_ENABLE}"
log_info "OPcache Memory: ${OPCACHE_MEMORY_CONSUMPTION}MB"
log_info "=========================================="

# =============================================================================
# Execute Command
# =============================================================================

# For php-fpm, run as root (master process) - PHP-FPM handles worker user switching via pool config
# For other commands (composer, php CLI, etc.), run as www-data
if [ "$1" = "php-fpm" ]; then
    log_info "Starting PHP-FPM as root (master process)..."
    exec "$@"
else
    log_info "Starting command as www-data: $*"
    exec su-exec www-data "$@"
fi