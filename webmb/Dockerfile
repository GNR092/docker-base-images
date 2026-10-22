FROM php:8.3.36-fpm-alpine3.23

# 1. Dependencias del sistema (Se agregó freetype-dev)
RUN apk update && apk add --no-cache \
    mysql-client \
    git \
    zip \
    unzip \
    oniguruma-dev \
    autoconf \
    build-base \
    imagemagick-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    libxml2-dev \
    icu-dev \
    freetype-dev

# 2. Configurar e Instalar extensiones de PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) \
    mysqli \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    gd \
    opcache \
    zip \
    bcmath \
    intl \
    soap

# 3. Composer
COPY --from=composer/composer:2-bin /composer /usr/bin/composer

# 4. Gestión de Usuarios
ARG PUID=1000
ARG PGID=1000

RUN deluser www-data || true \
    && delgroup www-data || true \
    && addgroup -g ${PGID} www-data \
    && adduser -u ${PUID} -G www-data -s /bin/sh -D www-data

WORKDIR /var/www/html

# 5. Configuración y Permisos
# Importante: chown debe ser recursivo para las carpetas writable de CI4
RUN chown -R www-data:www-data /var/www/html/ \
    && chmod -R 775 /var/www/html/

COPY zz-custom.conf /usr/local/etc/php-fpm.d/zz-custom.conf
COPY opcache-custom.ini /usr/local/etc/php/conf.d/opcache-custom.ini
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh && \
    git config --global core.fileMode false && \
    git config --global --add safe.directory /var/www/html && \
    mkdir -p /var/log/nginx && \
    chown www-data:www-data /var/log/nginx

ENV APP_MODE=new
EXPOSE 9000

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]