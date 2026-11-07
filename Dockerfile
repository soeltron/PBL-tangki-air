FROM php:8.3-cli-bookworm AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
        libonig-dev libzip-dev \
    && docker-php-ext-install pdo_mysql mbstring bcmath pcntl sockets zip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
WORKDIR /var/www
COPY backend/ ./
RUN mkdir -p bootstrap/cache storage/framework/cache/data storage/framework/sessions \
        storage/framework/testing storage/framework/views storage/logs \
    && composer install --no-dev --no-interaction --no-progress --prefer-dist --optimize-autoloader

FROM php:8.3-fpm-bookworm AS runtime

ENV TZ=Asia/Jakarta

RUN apt-get update && apt-get install -y --no-install-recommends \
        libonig-dev libzip-dev tzdata \
    && docker-php-ext-install pdo_mysql mbstring bcmath pcntl sockets zip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www
COPY --from=build --chown=www-data:www-data /var/www /var/www
COPY docker/php-fpm.conf /usr/local/etc/php-fpm.conf
COPY docker/php-fpm-pool.conf /usr/local/etc/php-fpm.d/www.conf

RUN mkdir -p bootstrap/cache storage/framework/cache/data storage/framework/sessions \
        storage/framework/testing storage/framework/views storage/logs \
    && chown -R www-data:www-data bootstrap/cache storage \
    && chmod -R ug+rwX bootstrap/cache storage

USER www-data
CMD ["php-fpm", "--nodaemonize"]