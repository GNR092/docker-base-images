#!/bin/sh
# =============================================================================
# Entrypoint híbrido: base php8.4-fpm-xdebug + lógica Laravel de weblvl
# =============================================================================
# 1. Sustituye env vars en configs PHP-FPM / PHP / Xdebug / OPcache (heredado
#    de php8.4-fpm-xdebug/entrypoint.sh). Requiere `gettext` (envsubst), que
#    ya viene en la imagen base.
# 2. Ajusta UID/GID de www-data (lógica weblvl).
# 3. Instala vendor, fija permisos y cachea Laravel (lógica weblvl).
# 4. Arranca PHP-FPM.
# =============================================================================
set -e

substitute_env_vars() {
    file="$1"
    if [ -f "$file" ]; then
        echo "[INFO] Substituting env vars in $file"
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

for config_file in \
    /usr/local/etc/php-fpm.d/www.conf \
    /usr/local/etc/php/conf.d/docker-php.ini \
    /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    /usr/local/etc/php/conf.d/opcache.ini; do
    substitute_env_vars "$config_file"
done

# --- Xdebug: prepara log y avisa en modo debug (igual que imagen base) ---
if [ "${XDEBUG_MODE:-off}" != "off" ]; then
    echo "[INFO] Xdebug mode: ${XDEBUG_MODE}"
    if [ -n "${XDEBUG_LOG:-}" ] && [ "${XDEBUG_LOG}" != "" ]; then
        touch "${XDEBUG_LOG}" 2>/dev/null || true
        chown www-data:www-data "${XDEBUG_LOG}" 2>/dev/null || true
        chmod 664 "${XDEBUG_LOG}" 2>/dev/null || true
    fi
    case "${XDEBUG_MODE}" in
        *debug*)
            if [ "${XDEBUG_CLIENT_HOST}" = "host.docker.internal" ]; then
                echo "[WARNING] En Linux usa --add-host=host.docker.internal:host-gateway o fija XDEBUG_CLIENT_HOST a tu IP."
            fi
            echo "[INFO] Xdebug step debugging -> ${XDEBUG_CLIENT_HOST}:${XDEBUG_CLIENT_PORT} (IDE key: ${XDEBUG_IDE_KEY})"
            ;;
    esac
else
    echo "[INFO] Xdebug disabled (XDEBUG_MODE=off)"
fi

mkdir -p /var/log/php-fpm /var/lib/php/sessions
chown -R www-data:www-data /var/log/php-fpm /var/lib/php/sessions 2>/dev/null || true
chmod 775 /var/log/php-fpm /var/lib/php/sessions 2>/dev/null || true

# --- weblvl: UID/GID dinámicos ---
PUID=${PUID:-1000}
PGID=${PGID:-1000}
echo "Starting with uid=${PUID} gid=${PGID}"

CURRENT_UID=$(id -u www-data 2>/dev/null)
CURRENT_GID=$(id -g www-data 2>/dev/null)

if [ "${CURRENT_UID}" != "${PUID}" ] || [ "${CURRENT_GID}" != "${PGID}" ]; then
    echo "Adjusting www-data uid/gid: ${CURRENT_UID}:${CURRENT_GID} -> ${PUID}:${PGID}"
    deluser www-data 2>/dev/null || true
    delgroup www-data 2>/dev/null || true
    addgroup -g "${PGID}" www-data
    adduser -u "${PUID}" -G www-data -s /sbin/nologin -D www-data
fi

cd /var/www/html

# --- weblvl: dependencias Laravel ---
if [ ! -d "vendor" ]; then
    echo "Vendor directory not found. Running composer install..."
    su-exec "${PUID}:${PGID}" composer install --no-dev --optimize-autoloader
    echo "Composer install finished."
fi

# --- weblvl: permisos ---
echo "Setting permissions for storage and bootstrap/cache..."
mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views bootstrap/cache
chown -R "${PUID}:${PGID}" storage bootstrap/cache
chmod -R 775 storage bootstrap/cache
echo "Permissions set successfully."

# --- weblvl: optimizaciones Laravel (se saltan si OPcache/Xdebug debug lo impiden) ---
if [ -f "artisan" ]; then
    echo "Running Laravel optimizations..."
    su-exec "${PUID}:${PGID}" php artisan config:cache || true
    su-exec "${PUID}:${PGID}" php artisan route:cache || true
    su-exec "${PUID}:${PGID}" php artisan view:cache || true
    echo "Laravel optimizations finished."
fi

echo "=========================================="
echo "PHP $(php -v | head -n1)"
echo "FPM listen: ${PHP_FPM_LISTEN:-9000} | PM: ${PHP_FPM_PM:-dynamic}"
echo "Xdebug mode: ${XDEBUG_MODE:-off}"
if [ "${XDEBUG_MODE:-off}" != "off" ]; then
    echo "Xdebug client: ${XDEBUG_CLIENT_HOST}:${XDEBUG_CLIENT_PORT}"
fi
echo "Python: $(python3 --version 2>&1)"
echo "=========================================="

if ! php-fpm -t; then
    echo "[ERROR] PHP-FPM configuration test failed"
    exit 1
fi

# php-fpm master corre como root y delega workers a www-data según pool config;
# cualquier otro comando corre como www-data.
if [ "$1" = "php-fpm" ]; then
    echo "Starting PHP-FPM..."
    exec "$@"
else
    echo "Starting command as www-data: $*"
    exec su-exec www-data "$@"
fi
