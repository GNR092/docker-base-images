# PHP 8.4-FPM Base Image

A production-ready, multi-stage Docker base image for PHP 8.4-FPM without Xdebug. Optimized for production deployments with comprehensive PHP extensions, security hardening, and environment-driven configuration.

## Features

- **Multi-stage build** for minimal production image size
- **PHP 8.4** with FPM (FastCGI Process Manager)
- **No Xdebug** - zero overhead for production
- **Production-ready** with security best practices (non-root user, disabled dangerous functions)
- **Comprehensive PHP extensions** for modern applications (Laravel, Symfony, etc.)
- **OPcache** optimized for production
- **Health checks** included
- **Environment-driven configuration** - no rebuild needed for config changes

## Included PHP Extensions

### Core Extensions
- bcmath, bz2, calendar, exif, gd, gmp, intl, ldap, mbstring
- mysqli, opcache, pcntl, pdo, pdo_mysql, pdo_pgsql, pdo_sqlite, pgsql
- posix, shmop, sockets, sysvmsg, sysvsem, sysvshm, zip, soap

### PECL Extensions
- **redis** - Redis client
- **memcached** - Memcached client
- **rdkafka** - Apache Kafka client
- **amqp** - RabbitMQ client

## Quick Start

### Build the Image

```bash
cd php8.4-fpm
docker build -t php8.4-fpm .
```

### Run with Docker Compose

Create a `docker-compose.yml`:

```yaml
version: '3.8'

services:
  php:
    build: ./php8.4-fpm
    container_name: php-app
    environment:
      # PHP-FPM
      - PHP_FPM_PM=dynamic
      - PHP_FPM_PM_MAX_CHILDREN=50
      - PHP_MEMORY_LIMIT=256M
      
      # OPcache
      - OPCACHE_ENABLE=1
      - OPCACHE_VALIDATE_TIMESTAMPS=0  # Set to 0 for production
      
      # Application
      - APP_ENV=production
    volumes:
      - ./src:/var/www/html
      - php-logs:/var/log/php-fpm
    ports:
      - "9000:9000"
    healthcheck:
      test: ["CMD", "php-fpm", "-t"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  php-logs:
```

## Environment Variables Reference

### PHP-FPM Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `PHP_FPM_LISTEN` | `9000` | Port to listen on |
| `PHP_FPM_PM` | `dynamic` | Process manager mode: `static`, `dynamic`, `ondemand` |
| `PHP_FPM_PM_MAX_CHILDREN` | `50` | Max child processes |
| `PHP_FPM_PM_START_SERVERS` | `5` | Initial servers (dynamic) |
| `PHP_FPM_PM_MIN_SPARE_SERVERS` | `5` | Min spare servers (dynamic) |
| `PHP_FPM_PM_MAX_SPARE_SERVERS` | `35` | Max spare servers (dynamic) |

### PHP Runtime

| Variable | Default | Description |
|----------|---------|-------------|
| `PHP_MEMORY_LIMIT` | `256M` | Memory limit per script |
| `PHP_MAX_EXECUTION_TIME` | `300` | Max execution time (seconds) |
| `PHP_UPLOAD_MAX_FILESIZE` | `100M` | Max upload file size |
| `PHP_POST_MAX_SIZE` | `100M` | Max POST data size |
| `PHP_DATE_TIMEZONE` | `UTC` | Default timezone |

### OPcache Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `OPCACHE_ENABLE` | `1` | Enable OPcache |
| `OPCACHE_ENABLE_CLI` | `0` | Enable OPcache for CLI |
| `OPCACHE_MEMORY_CONSUMPTION` | `128` | Memory in MB |
| `OPCACHE_INTERNED_STRINGS_BUFFER` | `8` | Interned strings buffer in MB |
| `OPCACHE_MAX_ACCELERATED_FILES` | `10000` | Max cached scripts |
| `OPCACHE_REVALIDATE_FREQ` | `2` | Revalidation frequency (seconds) |
| `OPCACHE_FAST_SHUTDOWN` | `1` | Fast shutdown sequence |
| `OPCACHE_VALIDATE_TIMESTAMPS` | `1` | Check for file updates (set to `0` for production) |

### Application

| Variable | Default | Description |
|----------|---------|-------------|
| `APP_ENV` | `production` | Application environment |
| `APP_DEBUG` | `false` | Debug mode |

### User/Group Mapping

| Variable | Default | Description |
|----------|---------|-------------|
| `PUID` | `1000` | User ID for www-data |
| `PGID` | `1000` | Group ID for www-data |

## Production Deployment Checklist

- [ ] `OPCACHE_VALIDATE_TIMESTAMPS=0`
- [ ] `APP_ENV=production`
- [ ] `APP_DEBUG=false`
- [ ] Set appropriate `PHP_MEMORY_LIMIT`
- [ ] Configure `PHP_FPM_PM` and limits for your workload
- [ ] Use secrets management for sensitive config
- [ ] Enable health checks in orchestrator

## Building with Custom Options

```bash
# Build for specific platform
docker build --platform linux/amd64 -t php8.4-fpm .

# Build with custom UID/GID
docker build --build-arg PUID=1000 --build-arg PGID=1000 -t php8.4-fpm .
```

## Security Notes

- Runs as non-root user `www-data` (UID/GID configurable via `PUID`/`PGID`)
- Dangerous PHP functions disabled by default
- `expose_php = Off`
- Minimal attack surface (multi-stage build excludes build tools)
- Read-only root filesystem compatible (with volume mounts for writable paths)

## Difference from php8.4-fpm-xdebug

This image is a simplified version without Xdebug:
- No Xdebug extension installed
- No Xdebug configuration files
- No Xdebug environment variables
- Smaller image size
- Zero runtime overhead from debugging features

Use `php8.4-fpm-xdebug` for development environments requiring step debugging.

## License

MIT License - See LICENSE file for details.