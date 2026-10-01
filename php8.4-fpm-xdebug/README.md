# PHP 8.4-FPM Base Image with Xdebug

A production-ready, multi-stage Docker base image for PHP 8.4-FPM with integrated Xdebug 3.x, configurable entirely via environment variables.

## Features

- **Multi-stage build** for minimal production image size
- **PHP 8.4** with FPM (FastCGI Process Manager)
- **Xdebug 3.4** integrated and fully configurable via environment variables
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
- **xdebug** - Debugging and profiling (configurable)

## Quick Start

### Build the Image

```bash
cd php8.4-fpm-xdebug
docker build -t php8.4-fpm-xdebug .
```

### Run with Docker Compose

Create a `docker-compose.yml`:

```yaml
version: '3.8'

services:
  php:
    build: ./php8.4-fpm-xdebug
    container_name: php-app
    environment:
      # PHP-FPM
      - PHP_FPM_PM=dynamic
      - PHP_FPM_PM_MAX_CHILDREN=50
      - PHP_MEMORY_LIMIT=256M
      
      # Xdebug (disabled by default for production)
      - XDEBUG_MODE=off
      # For development, enable with:
      # - XDEBUG_MODE=debug,develop
      # - XDEBUG_CLIENT_HOST=host.docker.internal
      # - XDEBUG_CLIENT_PORT=9003
      # - XDEBUG_IDE_KEY=PHPSTORM
      
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

### Development with Xdebug Enabled

```yaml
environment:
  - XDEBUG_MODE=debug,develop
  - XDEBUG_CLIENT_HOST=host.docker.internal  # Works on Docker Desktop Mac/Windows
  - XDEBUG_CLIENT_PORT=9003
  - XDEBUG_START_WITH_REQUEST=yes
  - XDEBUG_IDE_KEY=PHPSTORM
  - XDEBUG_LOG=/var/log/php-fpm/xdebug.log
  - XDEBUG_LOG_LEVEL=7
```

**For Linux hosts**, replace `host.docker.internal` with your host IP or use:
```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
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

### Xdebug Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `XDEBUG_MODE` | `off` | Modes: `off`, `debug`, `develop`, `trace`, `profile`, `coverage`, `gcstats` (comma-separated) |
| `XDEBUG_CLIENT_HOST` | `host.docker.internal` | IDE host for debugging |
| `XDEBUG_CLIENT_PORT` | `9003` | IDE port for debugging |
| `XDEBUG_START_WITH_REQUEST` | `yes` | `yes`, `no`, `trigger` |
| `XDEBUG_DISCOVER_CLIENT_HOST` | `false` | Auto-detect client via headers |
| `XDEBUG_IDE_KEY` | `PHPSTORM` | IDE key for DBGp proxy |
| `XDEBUG_LOG` | `/var/log/php-fpm/xdebug.log` | Log file path |
| `XDEBUG_LOG_LEVEL` | `7` | Log verbosity (bitmask: 1=errors, 2=warnings, 4=info, 8=debug, 16=trace) |
| `XDEBUG_MAX_NESTING_LEVEL` | `256` | Max function nesting level |
| `XDEBUG_MAX_STACK_FRAMES` | `100` | Max stack frames in traces |
| `XDEBUG_SHOW_ERROR_TRACE` | `false` | Show trace on errors |
| `XDEBUG_SHOW_EXCEPTION_TRACE` | `false` | Show trace on exceptions |
| `XDEBUG_SHOW_LOCAL_VARS` | `false` | Show locals in stack traces |

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

## Xdebug Modes Explained

| Mode | Description | Use Case |
|------|-------------|----------|
| `off` | **Disabled** (default) | Production - zero overhead |
| `debug` | Step debugging | Interactive debugging with IDE |
| `develop` | Development helpers | Enhanced `var_dump`, notices |
| `trace` | Function tracing | Performance analysis |
| `profile` | Profiling | Cachegrind-compatible profiles |
| `coverage` | Code coverage | PHPUnit coverage reports |
| `gcstats` | GC statistics | Garbage collection analysis |

**Combine modes**: `XDEBUG_MODE=debug,develop,trace`

## IDE Configuration

### PhpStorm / IntelliJ

1. **Settings → PHP → Debug** → Set Xdebug port to `9003`
2. **Settings → PHP → Servers** → Add server with path mappings
3. **Run → Start Listening for PHP Debug Connections**
4. Set `XDEBUG_MODE=debug` and `XDEBUG_IDE_KEY=PHPSTORM`

### VS Code (PHP Debug)

```json
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Listen for Xdebug",
      "type": "php",
      "request": "launch",
      "port": 9003,
      "pathMappings": {
        "/var/www/html": "${workspaceFolder}"
      }
    }
  ]
}
```

## Production Deployment Checklist

- [ ] `XDEBUG_MODE=off` (default)
- [ ] `OPCACHE_VALIDATE_TIMESTAMPS=0`
- [ ] `APP_ENV=production`
- [ ] `APP_DEBUG=false`
- [ ] Set appropriate `PHP_MEMORY_LIMIT`
- [ ] Configure `PHP_FPM_PM` and limits for your workload
- [ ] Use secrets management for sensitive config
- [ ] Enable health checks in orchestrator

## Building with Custom Options

```bash
# Build with specific Xdebug version
docker build --build-arg XDEBUG_VERSION=3.4.0 -t php8.4-fpm-xdebug .

# Build for specific platform
docker build --platform linux/amd64 -t php8.4-fpm-xdebug .
```

## Security Notes

- Runs as non-root user `www-data` (UID/GID configurable via `PUID`/`PGID`)
- Dangerous PHP functions disabled by default
- `expose_php = Off`
- Minimal attack surface (multi-stage build excludes build tools)
- Read-only root filesystem compatible (with volume mounts for writable paths)

## License

MIT License - See LICENSE file for details.