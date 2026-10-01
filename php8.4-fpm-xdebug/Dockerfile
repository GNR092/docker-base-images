# =============================================================================
# PHP 8.4-FPM Base Image with Xdebug - Multi-stage Build
# =============================================================================
# Stage 1: Builder - Install build dependencies and compile extensions
# =============================================================================
FROM php:8.4-fpm-alpine3.20 AS builder

# Install build dependencies for PHP extensions and Xdebug
RUN apk update --no-cache && \
    apk add --no-cache \
        autoconf \
        build-base \
        gcc \
        g++ \
        make \
        pkgconf \
        linux-headers \
        libtool \
        libxml2-dev \
        icu-dev \
        oniguruma-dev \
        libzip-dev \
        libpng-dev \
        libjpeg-turbo-dev \
        libwebp-dev \
        freetype-dev \
        gmp-dev \
        sqlite-dev \
        postgresql-dev \
        zlib-dev \
        curl-dev \
        openssl-dev \
        bzip2-dev \
        readline-dev \
        imap-dev \
        openldap-dev \
        cyrus-sasl-dev \
        libmemcached-dev \
        librdkafka-dev \
        rabbitmq-c-dev \
    && rm -rf /var/cache/apk/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp && \
    docker-php-ext-configure ldap && \
    docker-php-ext-install -j$(nproc) \
        bcmath \
        bz2 \
        calendar \
        exif \
        gd \
        gmp \
        intl \
        ldap \
        mbstring \
        mysqli \
        opcache \
        pcntl \
        pdo \
        pdo_mysql \
        pdo_pgsql \
        pdo_sqlite \
        pgsql \
        posix \
        shmop \
        sockets \
        sysvmsg \
        sysvsem \
        sysvshm \
        zip \
        soap \
    && docker-php-ext-enable opcache

# Install PECL extensions (redis, memcached, etc.)
RUN pecl install redis && \
    docker-php-ext-enable redis && \
    pecl install memcached && \
    docker-php-ext-enable memcached && \
    pecl install rdkafka && \
    docker-php-ext-enable rdkafka && \
    pecl install amqp && \
    docker-php-ext-enable amqp

# =============================================================================
# Stage 2: Xdebug Builder - Compile Xdebug separately for cleaner layers
# =============================================================================
FROM php:8.4-fpm-alpine3.20 AS xdebug_builder

# Install build dependencies for Xdebug
RUN apk update --no-cache && \
    apk add --no-cache \
        autoconf \
        build-base \
        gcc \
        g++ \
        make \
        pkgconf \
        linux-headers \
        libtool \
    && rm -rf /var/cache/apk/*

# Install Xdebug
ARG XDEBUG_VERSION=3.4.0
RUN pecl install xdebug-${XDEBUG_VERSION}

# =============================================================================
# Stage 3: Runtime - Minimal production image
# =============================================================================
FROM php:8.4-fpm-alpine3.20 AS runtime

# Install only runtime dependencies
RUN apk update --no-cache && \
    apk add --no-cache \
        # Core libraries
        libxml2 \
        icu \
        oniguruma \
        libzip \
        libpng \
        libjpeg-turbo \
        libwebp \
        freetype \
        gmp \
        sqlite-libs \
        postgresql-libs \
        zlib \
        curl \
        openssl \
        bzip2 \
        readline \
        c-client \
        openldap \
        cyrus-sasl \
        libmemcached \
        librdkafka \
        rabbitmq-c \
        # Utilities
        git \
        bash \
        curl \
        wget \
        unzip \
        su-exec \
        tzdata \
        ca-certificates \
        gettext \
    && rm -rf /var/cache/apk/*

# Copy PHP extensions and their configuration from builder stage
# Using exact extension directory name to avoid wildcard issues
COPY --from=builder /usr/local/lib/php/extensions/no-debug-non-zts-20240924/ /usr/local/lib/php/extensions/no-debug-non-zts-20240924/
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# Copy Xdebug from xdebug_builder stage
COPY --from=xdebug_builder /usr/local/lib/php/extensions/no-debug-non-zts-20240924/xdebug.so /usr/local/lib/php/extensions/no-debug-non-zts-20240924/xdebug.so

# Xdebug configuration (environment-driven template)
COPY php/conf.d/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Copy Composer from official image
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# =============================================================================
# Configuration Files
# =============================================================================

# PHP-FPM configuration
COPY php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY php-fpm.conf /usr/local/etc/php-fpm.conf

# PHP configuration
COPY php/conf.d/docker-php.ini /usr/local/etc/php/conf.d/docker-php.ini

# Xdebug configuration (environment-driven) - already copied from xdebug_builder stage
# COPY php/conf.d/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# OPcache configuration
COPY php/conf.d/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

# Entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# =============================================================================
# User and Permissions
# =============================================================================

# Create non-root user (using www-data which exists in php:fpm-alpine)
ARG PUID=1000
ARG PGID=1000

# Only change UID/GID if they differ from defaults (82:82 in Alpine php image)
# This avoids "group in use" errors when the defaults are already correct
RUN CURRENT_UID=$(id -u www-data) && \
    CURRENT_GID=$(id -g www-data) && \
    if [ "${CURRENT_UID}" != "${PUID}" ] || [ "${CURRENT_GID}" != "${PGID}" ]; then \
        # Change UID/GID of existing www-data user/group
        usermod -u ${PUID} www-data 2>/dev/null || true && \
        groupmod -g ${PGID} www-data 2>/dev/null || true && \
        # Fix ownership of files created by the old UID/GID
        find / -user ${CURRENT_UID} -exec chown -h www-data {} \; 2>/dev/null || true && \
        find / -group ${CURRENT_GID} -exec chgrp -h www-data {} \; 2>/dev/null || true; \
    fi

WORKDIR /var/www/html

# Set proper permissions
RUN mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 775 /var/www/html && \
    mkdir -p /var/log/php-fpm && \
    chown -R www-data:www-data /var/log/php-fpm

# =============================================================================
# Environment Variables (with defaults for production)
# =============================================================================

# PHP-FPM
ENV PHP_FPM_LISTEN=9000
ENV PHP_FPM_PM=dynamic
ENV PHP_FPM_PM_MAX_CHILDREN=50
ENV PHP_FPM_PM_START_SERVERS=5
ENV PHP_FPM_PM_MIN_SPARE_SERVERS=5
ENV PHP_FPM_PM_MAX_SPARE_SERVERS=35

# PHP Runtime
ENV PHP_MEMORY_LIMIT=256M
ENV PHP_MAX_EXECUTION_TIME=300
ENV PHP_UPLOAD_MAX_FILESIZE=100M
ENV PHP_POST_MAX_SIZE=100M
ENV PHP_DATE_TIMEZONE=UTC

# Xdebug Configuration (disabled by default for production)
ENV XDEBUG_MODE=off
ENV XDEBUG_CLIENT_HOST=host.docker.internal
ENV XDEBUG_CLIENT_PORT=9003
ENV XDEBUG_START_WITH_REQUEST=yes
ENV XDEBUG_DISCOVER_CLIENT_HOST=false
ENV XDEBUG_LOG_LEVEL=7
ENV XDEBUG_LOG=/var/log/php-fpm/xdebug.log
ENV XDEBUG_IDE_KEY=PHPSTORM
ENV XDEBUG_MAX_NESTING_LEVEL=256
ENV XDEBUG_MAX_STACK_FRAMES=100
ENV XDEBUG_SHOW_ERROR_TRACE=false
ENV XDEBUG_SHOW_EXCEPTION_TRACE=false
ENV XDEBUG_SHOW_LOCAL_VARS=false

# OPcache
ENV OPCACHE_ENABLE=1
ENV OPCACHE_ENABLE_CLI=0
ENV OPCACHE_MEMORY_CONSUMPTION=128
ENV OPCACHE_INTERNED_STRINGS_BUFFER=8
ENV OPCACHE_MAX_ACCELERATED_FILES=10000
ENV OPCACHE_REVALIDATE_FREQ=2
ENV OPCACHE_FAST_SHUTDOWN=1
ENV OPCACHE_VALIDATE_TIMESTAMPS=1

# Application
ENV APP_ENV=production
ENV APP_DEBUG=false

# =============================================================================
# Health Check
# =============================================================================

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD php-fpm -t || exit 1

# =============================================================================
# Expose and Entry
# =============================================================================

EXPOSE 9000

# Run entrypoint as root (needed for config substitution), then drop to www-data via su-exec
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm"]