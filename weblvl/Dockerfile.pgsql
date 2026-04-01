# Stage 1: Builder - for Composer installation
FROM composer:latest AS composer_builder

# Stage 2: Application - PHP-FPM with Alpine Linux
FROM php:8.3.8-fpm-alpine3.20

# Set working directory
WORKDIR /var/www/html

# Install system dependencies required for PHP extensions and Composer
# Using --no-cache to reduce image size and cleaning up apk cache
RUN apk update --no-cache && \
    apk add --no-cache \
        libzip-dev \
        libpng-dev \
        jpeg-dev \
        libwebp-dev \
        freetype-dev \
        icu-dev \
        gmp-dev \
        oniguruma-dev \
        git \
        curl \
        unzip \
        bash \
        make \
        gcc \
        g++ \
        autoconf \
        libc-dev \
        pkgconf \
        su-exec \
        sqlite-dev \
        libxml2-dev \
        postgresql-dev \
    && rm -rf /var/cache/apk/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp && \
      docker-php-ext-install -j$(nproc) \
          pdo_pgsql \
          pgsql \
          mbstring \
          exif \
          pcntl \
          bcmath \
          gd \
          zip \
          intl \
          gmp \
          posix && \
      docker-php-ext-enable opcache && \
      pecl install redis && \
      docker-php-ext-enable redis

# Copy Composer binary from builder stage
COPY --from=composer_builder /usr/bin/composer /usr/bin/composer

# Expose port 9000 for PHP-FPM
EXPOSE 9000

# Set entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm"]
