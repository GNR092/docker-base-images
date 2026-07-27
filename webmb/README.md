# Configuración PHP-FPM + Nginx + OPcache para CI4

Tres archivos de configuración listos para producción, reutilizables en cualquier proyecto CodeIgniter 4 con Docker.

---

## Archivos

```
├── nginx.conf.example      # Template completo Nginx (para /etc/nginx/nginx.conf)
├── zz-custom.conf          # PHP-FPM pool config (para /usr/local/etc/php-fpm.d/zz-custom.conf)
└── opcache-custom.ini      # OPcache config (para /usr/local/etc/php/conf.d/opcache-custom.ini)
```

---

## 1. `nginx.conf.example`

Configuración completa de Nginx optimizada para PHP-FPM y CodeIgniter 4.

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
| `__PHP_SERVICE__` | Host del servicio PHP-FPM (ej: `php-fpm`, `app`) |

**Características:**
- `worker_processes auto` + `worker_connections 8192`
- Gzip + tipos MIME optimizados
- `client_max_body_size 100M`
- FastCGI buffers tuneados (600s timeouts)
- Content-Security-Policy para CI4 con soporte a Webpack/workers
- Bloqueo de archivos ocultos y carpetas sensibles de CI4 (`system`, `writable`, `vendor`)

---

## 2. `zz-custom.conf`

Configuración del pool PHP-FPM optimizada para CI4. Se carga **último** gracias al prefijo `zz-`.

```ini
[www]
pm = dynamic
pm.max_children = 200
pm.start_servers = 50
pm.min_spare_servers = 30
pm.max_spare_servers = 150
pm.max_requests = 1000

request_terminate_timeout = 600s
request_slowlog_timeout = 10s
slowlog = /proc/self/fd/2

php_admin_value[memory_limit] = 256M
php_admin_value[upload_max_filesize] = 64M
php_admin_value[post_max_size] = 64M
php_admin_value[max_execution_time] = 600
php_admin_value[max_input_time] = 600

php_flag[display_errors] = on
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
- 16GB RAM / 256M = 64
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

---

## Referencias

- [PHP-FPM Config](https://www.php.net/manual/en/install.fpm.configuration.php)
- [OPcache Config](https://www.php.net/manual/en/opcache.configuration.php)
- [Nginx + PHP-FPM](https://www.nginx.com/resources/wiki/start/topics/examples/phpfcgi/)
