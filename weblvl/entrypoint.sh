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

# Cambiar al directorio de trabajo
cd /var/www/html

# 1. Validar Dependencias
if [ ! -d "vendor" ]; then
    echo "Vendor directory not found. Running composer install..."
    composer install --no-dev --optimize-autoloader
    echo "Composer install finished."
fi

# 2. Gestión de Permisos (Dinámica)
echo "Setting permissions for storage and bootstrap/cache..."

# Aseguramos que existan las carpetas antes de cambiar permisos para evitar errores
mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views bootstrap/cache

# Cambiamos el dueño a todo el proyecto (opcional pero recomendado) 
# y específicamente los permisos de escritura a las carpetas de Laravel
chown -R www-data:www-data /var/www/html
chmod -R 777 /var/www/html/storage /var/www/html/bootstrap/cache

echo "Permissions set successfully."

# 3. Optimizaciones de Laravel
# Solo corremos esto si artisan existe (para evitar errores en instalaciones limpias)
if [ -f "artisan" ]; then
    echo "Running Laravel optimizations..."
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
    echo "Laravel optimizations finished."
fi

# 4. Ejecutar PHP-FPM
echo "Starting PHP-FPM..."
# Usamos exec para que php-fpm tome el PID 1 y reciba las señales de Docker directamente
exec php-fpm