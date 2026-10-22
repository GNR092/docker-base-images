FROM php:8.5.12-fpm-alpine3.23

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/install-php-extensions
RUN chmod +x /usr/local/bin/install-php-extensions && \
    install-php-extensions bcmath exif gd gmp intl opcache pcntl pdo_mysql pdo_pgsql pgsql redis zip mysqli

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN apk add --no-cache gettext tzdata && rm -rf /var/cache/apk/* && \
    deluser www-data && delgroup www-data 2>/dev/null; \
    addgroup -g 1000 www-data && adduser -u 1000 -G www-data -s /sbin/nologin -D www-data

WORKDIR /var/www/html
