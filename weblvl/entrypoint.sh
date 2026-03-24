#!/bin/sh

# Función para apagar PHP-FPM de forma elegante
_term() {
  echo "Caught SIGTERM signal! Shutting down PHP-FPM..."
  kill -QUIT "$child_pid"
  wait "$child_pid"
  exit 0
}

# Atrapar SIGTERM
trap _term SIGTERM

# UID/GID dinámicos con valores por defecto
PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "Starting with uid=${PUID} gid=${PGID}"

# Ajustar uid/gid de www-data para que coincida con el host
# Así php-fpm.conf sigue usando "user = www-data" sin modificaciones
CURRENT_UID=$(id -u www-data 2>/dev/null)
CURRENT_GID=$(id -g www-data 2>/dev/null)

if [ "${CURRENT_UID}" != "${PUID}" ] || [ "${CURRENT_GID}" != "${PGID}" ]; then
    echo "Adjusting www-data uid/gid: ${CURRENT_UID}:${CURRENT_GID} -> ${PUID}:${PGID}"
    deluser www-data 2>/dev/null || true
    delgroup www-data 2>/dev/null || true
    addgroup -g "${PGID}" www-data
    adduser -u "${PUID}" -G www-data -s /sbin/nologin -D www-data
fi

# Cambiar al directorio de trabajo
cd /var/www/html

# 1. Validar Dependencias
if [ ! -d "vendor" ]; then
    echo "Vendor directory not found. Running composer install..."
    su-exec "${PUID}:${PGID}" composer install --no-dev --optimize-autoloader
    echo "Composer install finished."
fi

# 2. Gestión de Permisos
echo "Setting permissions for storage and bootstrap/cache..."
mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views bootstrap/cache
chown -R "${PUID}:${PGID}" storage bootstrap/cache
chmod -R 775 storage bootstrap/cache
echo "Permissions set successfully."

# 3. Optimizaciones de Laravel
if [ -f "artisan" ]; then
    echo "Running Laravel optimizations..."
    su-exec "${PUID}:${PGID}" php artisan config:cache
    su-exec "${PUID}:${PGID}" php artisan route:cache
    su-exec "${PUID}:${PGID}" php artisan view:cache
    echo "Laravel optimizations finished."
fi

# 4. Ejecutar PHP-FPM (corre como root y hace drop a www-data según php-fpm.conf)
echo "Starting PHP-FPM..."
exec php-fpm