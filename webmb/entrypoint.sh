#!/bin/sh
set -e

APP_DIR="/var/www/html"

echo "Running as UID=$(id -u) GID=$(id -g)"

if [ ! -f "${APP_DIR}/composer.json" ]; then
    if [ "${APP_MODE}" = "existing" ]; then
        echo "APP_MODE is 'existing' but composer.json is missing"
        exit 1
    fi
    echo "No composer.json found, creating CodeIgniter project"
    composer create-project codeigniter4/appstarter "${APP_DIR}" --no-interaction
else
    if [ ! -f "${APP_DIR}/vendor/autoload.php" ]; then
        echo "vendor/autoload.php not found, running composer install"
        composer install --no-dev --optimize-autoloader --no-interaction
    fi

    if [ -f "${APP_DIR}/spark" ]; then
        php "${APP_DIR}/spark" cache:clear || true
    fi
fi

mkdir -p "${APP_DIR}/writable/cache" \
         "${APP_DIR}/writable/session" \
         "${APP_DIR}/writable/logs" \
         "${APP_DIR}/writable/uploads"

chown -R www-data:www-data "${APP_DIR}/writable" || true
chmod -R 775 "${APP_DIR}/writable" || true

exec "$@"
