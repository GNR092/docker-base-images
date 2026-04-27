#!/bin/sh

APP_DIR="/var/www/html"

echo "Running as UID=$(id -u) GID=$(id -g)"

if [ ! -f "${APP_DIR}/composer.json" ]; then
    echo "No composer.json found, creating CodeIgniter project"
    composer create-project codeigniter4/appstarter "${APP_DIR}" --no-interaction
else
    if [ "${APP_MODE}" = "new" ]; then
        echo "APP_MODE is 'new' but project already exists, skipping create-project"
    elif [ "${APP_MODE}" = "existing" ]; then
        if [ ! -d "${APP_DIR}/vendor" ]; then
            echo "No vendor directory found, running composer install"
            composer install --no-dev --optimize-autoloader
        fi

        if [ -f "${APP_DIR}/spark" ]; then
            php "${APP_DIR}/spark" cache:clear || true
        fi
    fi
fi

mkdir -p "${APP_DIR}/writable/cache" \
         "${APP_DIR}/writable/session" \
         "${APP_DIR}/writable/logs" \
         "${APP_DIR}/writable/uploads"

chmod -R 775 "${APP_DIR}/writable" || true

exec "$@"
