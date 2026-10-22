#!/bin/sh
set -e

APP_DIR="/var/www/html"
LOCK_STAMP="${APP_DIR}/writable/.composer-lock.md5"

echo "Running as UID=$(id -u) GID=$(id -g)"

if [ ! -f "${APP_DIR}/composer.json" ]; then
    if [ "${APP_MODE}" = "existing" ]; then
        echo "APP_MODE is 'existing' but composer.json is missing"
        exit 1
    fi
    echo "No composer.json found, creating CodeIgniter project"
    composer create-project codeigniter4/appstarter "${APP_DIR}" --no-interaction
fi

mkdir -p "${APP_DIR}/writable/cache" \
         "${APP_DIR}/writable/session" \
         "${APP_DIR}/writable/logs" \
         "${APP_DIR}/writable/uploads"

LOCK_SUM=""
[ -f "${APP_DIR}/composer.lock" ] && LOCK_SUM=$(php -r "echo md5_file('${APP_DIR}/composer.lock');")

if [ ! -f "${APP_DIR}/vendor/autoload.php" ] || [ "${LOCK_SUM}" != "$(cat "${LOCK_STAMP}" 2>/dev/null)" ]; then
    echo "Dependencias desactualizadas, ejecutando composer install"
    GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0="${APP_DIR}" \
        composer install --no-dev --optimize-autoloader --no-interaction
    echo "${LOCK_SUM}" > "${LOCK_STAMP}" 2>/dev/null || true

    if [ -f "${APP_DIR}/spark" ]; then
        php "${APP_DIR}/spark" cache:clear || true
    fi
elif [ "${APP_CLEAR_CACHE}" = "1" ] && [ -f "${APP_DIR}/spark" ]; then
    php "${APP_DIR}/spark" cache:clear || true
fi

if [ "$(id -u)" = "0" ]; then
    chown -R www-data:www-data "${APP_DIR}/writable" || true
fi
chmod -R 775 "${APP_DIR}/writable" || true

exec "$@"
