#!/bin/sh
set -e

PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "Starting with uid=${PUID} gid=${PGID}"

CURRENT_UID=$(id -u www-data 2>/dev/null || true)
CURRENT_GID=$(id -g www-data 2>/dev/null || true)

if [ "${CURRENT_GID}" != "${PGID}" ]; then
    echo "Adjusting www-data gid: ${CURRENT_GID} -> ${PGID}"
    groupmod -o -g "${PGID}" www-data
fi

if [ "${CURRENT_UID}" != "${PUID}" ]; then
    echo "Adjusting www-data uid: ${CURRENT_UID} -> ${PUID}"
    usermod -o -u "${PUID}" www-data
fi

cd /var/www/html

mkdir -p /var/www/.cache /var/www/.composer
chown "${PUID}:${PGID}" /var/www/.cache /var/www/.composer

if [ ! -f "vendor/autoload.php" ]; then
    if [ -f "composer.json" ]; then
        echo "vendor/ not found. Running composer install..."
        gosu "${PUID}:${PGID}" composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist
        echo "Composer install finished."
    else
        echo "WARNING: composer.json not found in /var/www/html; skipping composer install."
    fi
fi

echo "Setting permissions for storage and bootstrap/cache..."
mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views bootstrap/cache
chown -R "${PUID}:${PGID}" storage bootstrap/cache
chmod -R 775 storage bootstrap/cache
echo "Permissions set successfully."

if [ -f "artisan" ] && [ -f "vendor/autoload.php" ]; then
    echo "Running Laravel optimizations..."
    gosu "${PUID}:${PGID}" php artisan config:clear
    gosu "${PUID}:${PGID}" php artisan optimize
    gosu "${PUID}:${PGID}" php artisan view:cache
    gosu "${PUID}:${PGID}" php artisan cache:clear || echo "WARNING: cache:clear failed"
    if [ -d "public" ] && [ ! -e "public/storage" ] && [ ! -L "public/storage" ]; then
        gosu "${PUID}:${PGID}" php artisan storage:link
    fi
    echo "Laravel optimizations finished."
fi

if [ "$#" -eq 0 ]; then
    set -- php-fpm
fi

if [ "$1" = "php-fpm" ]; then
    echo "Starting PHP-FPM..."
    exec "$@"
fi

if ! command -v "$1" >/dev/null 2>&1 && [ -f "artisan" ]; then
    set -- php artisan "$@"
fi

echo "Starting worker as ${PUID}:${PGID}: $*"
exec gosu "${PUID}:${PGID}" "$@"
