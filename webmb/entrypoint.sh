#!/bin/sh

APP_DIR="/var/www/html"
PUID=${HOST_UID:-1000}
PGID=${HOST_GID:-1000}

# Muestra los UID/GID configurados
echo "Running with PUID=${PUID} PGID=${PGID}"
echo "User nobody in container should now have UID=${PUID} GID=${PGID}"

# Verifica si existe composer.json para saber si es un proyecto nuevo o existente
if [ ! -f "${APP_DIR}/composer.json" ]; then
    # Instala CodeIgniter si no existe el proyecto
    composer create-project codeigniter4/appstarter ${APP_DIR} --no-interaction

    # Mueve archivos si composer los puso en una subcarpeta
    if [ -d "${APP_DIR}/appstarter" ]; then
        mv ${APP_DIR}/appstarter/* ${APP_DIR}/appstarter/.* ${APP_DIR}/ 2>/dev/null || true
        rmdir ${APP_DIR}/appstarter
    fi

    # Ajusta permisos del proyecto recién creado
    chown -R www-data:www-data "${APP_DIR}" || true
    chmod -R 775 "${APP_DIR}" || true

else
    # Si el proyecto existe, verifica el modo de operación
    if [ "$APP_MODE" = "new" ]; then
        echo "APP_MODE es 'new', pero el directorio no está vacío. Omitiendo la creación de un nuevo proyecto."
    elif [ "$APP_MODE" = "existing" ]; then
        # Instala dependencias si no existe vendor
        if [ ! -d "${APP_DIR}/vendor" ]; then
            su www-data -c "composer install --no-dev --optimize-autoloader"
        fi

        # Limpia caché si existe spark
        if [ -f "${APP_DIR}/spark" ]; then
            su www-data -c "php ${APP_DIR}/spark cache:clear || true"
        fi
    fi
fi

# Ajusta permisos de la carpeta writable
chown -R www-data:www-data "${APP_DIR}/writable" || true
chmod -R 775 "${APP_DIR}/writable" || true

# Da permisos de lectura y ejecución al resto de la aplicación
chmod -R 755 "${APP_DIR}/" || true

# Inicia PHP-FPM
exec "$@"
