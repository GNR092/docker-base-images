# Configuración Genérica PHP-FPM + Nginx + OPcache

Tres archivos de configuración listos para producción, reutilizables en cualquier proyecto Laravel/PHP con Docker.

---

## Archivos

```
├── nginx.conf.example      # Template completo Nginx (para /etc/nginx/nginx.conf)
├── zz-custom.conf          # PHP-FPM pool config (para /usr/local/etc/php-fpm.d/zz-custom.conf)
└── opcache-custom.ini      # OPcache config (para /usr/local/etc/php/conf.d/opcache-custom.ini)
```

---

## 1. `nginx.conf.example`

Configuración completa de Nginx optimizada para PHP-FPM.

**Uso:**
```bash
sed -e 's/__DOMAIN__/tudominio.com/g' \
    -e 's|__ROOT__|/var/www/html/public|g' \
    -e 's/__PHP_SERVICE__/php-fpm/g' \
    nginx.conf.example > /etc/nginx/nginx.conf
```

**Placeholders:**
| Placeholder | Descripción |
|-------------|-------------|
| `__DOMAIN__` | Dominio (ej: `app.example.com`) |
| `__ROOT__` | Document root (ej: `/var/www/html/public`) |
| `__PHP_SERVICE__` | Host del servicio PHP-FPM (ej: `php-fpm`, `app-php`) |

**Características:**
- `worker_processes auto` + `worker_connections 8192`
- Gzip + tipos MIME optimizados
- `client_max_body_size 100M`
- FastCGI buffers tuneados (600s timeouts)
- Bloqueo de archivos ocultos y carpetas sensibles (`vendor`, `storage`, `bootstrap/cache`)
- Headers HTTPS para reverse proxy (Traefik, Caddy, etc.)

---

## 2. `zz-custom.conf`

Configuración del pool PHP-FPM para producción. Se carga **último** gracias al prefijo `zz-`.

```ini
[www]
pm = dynamic
pm.max_children = 50
pm.start_servers = 10
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.max_requests = 1000

request_terminate_timeout = 300s
request_slowlog_timeout = 10s
slowlog = /proc/self/fd/2

php_admin_value[memory_limit] = 256M
php_admin_value[upload_max_filesize] = 64M
php_admin_value[post_max_size] = 64M
php_admin_value[max_execution_time] = 300
php_admin_value[max_input_time] = 300

php_flag[display_errors] = off
php_admin_flag[log_errors] = on
php_admin_value[error_log] = /proc/self/fd/2
php_admin_flag[expose_php] = off
```

**Ajuste de `pm.max_children`:**
```
RAM disponible para PHP / memory_limit ≈ max_children

Ejemplos:
- 2GB RAM / 256M = 8 (conservador)
- 4GB RAM / 256M = 16
- 8GB RAM / 256M = 32
```

**Montaje Docker:**
```yaml
volumes:
  - ./zz-custom.conf:/usr/local/etc/php-fpm.d/zz-custom.conf:ro
```

---

## 3. `opcache-custom.ini`

OPcache optimizado para producción.

```ini
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=10000
opcache.validate_timestamps=0
opcache.revalidate_freq=0
opcache.save_comments=1
opcache.fast_shutdown=1
opcache.jit_buffer_size=64M
```

**Claves:**
| Directiva | Valor | Por qué |
|-----------|-------|---------|
| `validate_timestamps` | `0` | No stat() en cada request (requiere cache clear en deploy) |
| `memory_consumption` | `128` | MB para caché (ajusta según tamaño código) |
| `max_accelerated_files` | `10000` | Suficiente para apps medianas/grandes |
| `jit_buffer_size` | `64M` | JIT compiler (PHP 8.1+) |

**Montaje Docker:**
```yaml
volumes:
  - ./opcache-custom.ini:/usr/local/etc/php/conf.d/opcache-custom.ini:ro
```

**Deploy con OPcache:**
```bash
# Requerido si validate_timestamps=0
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Para limpiar
php artisan config:clear
php artisan view:clear
```

---

## Uso Rápido (Docker Compose)

```yaml
services:
  nginx:
    image: nginx:alpine
    volumes:
      - ./nginx.conf.example:/etc/nginx/nginx.conf:ro
    depends_on:
      - php-fpm

  php-fpm:
    image: php:8.3-fpm-alpine
    volumes:
      - ./zz-custom.conf:/usr/local/etc/php-fpm.d/zz-custom.conf:ro
      - ./opcache-custom.ini:/usr/local/etc/php/conf.d/opcache-custom.ini:ro
      - ./app:/var/www/html
```

---

## Referencias

- [PHP-FPM Config](https://www.php.net/manual/en/install.fpm.configuration.php)
- [OPcache Config](https://www.php.net/manual/en/opcache.configuration.php)
- [Nginx + PHP-FPM](https://www.nginx.com/resources/wiki/start/topics/examples/phpfcgi/)