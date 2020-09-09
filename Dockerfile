# The different stages of this Dockerfile are meant to be built into separate images
# https://docs.docker.com/develop/develop-images/multistage-build/#stop-at-a-specific-build-stage
# https://docs.docker.com/compose/compose-file/#target

# https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact
ARG PHP_VERSION=7.4
ARG NGINX_VERSION=1.19

# ---------
# PHP stage
# ---------
FROM php:${PHP_VERSION}-fpm-alpine AS php

WORKDIR /app

# Setup environment
RUN set -eux; \
    \
    apk update; \
    apk add --no-cache \
        bash \
        curl \
        unzip \
        # Alpine package for "imagemagick" contains ~120 .so files,
        # see: https://github.com/docker-library/wordpress/pull/497
        imagemagick \
        # Required to check connectivity
        mysql-client; \
    \
    # Get all php requirements
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        # Required for gd
        freetype-dev libjpeg-turbo-dev libpng-dev \
        gettext-dev \
        # Required for imap
        imap-dev \
        # Required for intl
        icu-dev \
        # Required for zip
        libzip-dev \
        # Required for imagick
        imagemagick-dev; \
    docker-php-ext-configure gd --with-freetype --with-jpeg >/dev/null; \
    docker-php-ext-install -j "$(nproc)" \
        exif \
        gd \
        gettext \
        imap \
        intl \
        mysqli \
        opcache \
        sockets \
        zip \
        >/dev/null; \
    pecl install imagick >/dev/null; \
    pecl install apcu >/dev/null; \
    pecl clear-cache; \
    docker-php-ext-enable \
        imagick \
        apcu \
        opcache; \
    \
    # Find packages to keep, so we can safely delete dev packages
    RUN_DEPS="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions | \
            tr ',' '\n' | \
            sort -u | \
            awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --virtual .phpexts-rundeps $RUN_DEPS; \
    \
    # Remove building tools for smaller container size
    apk del .build-deps; \
    \
    # Get WP CLI and autocompletion
    curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar; \
    chmod +x /usr/local/bin/wp

COPY php/wp-plugin-install.sh /usr/local/bin/wp-plugin-install
COPY php/wp-theme-install.sh /usr/local/bin/wp-theme-install
COPY php/wp-config.php ./

# Setup application
RUN set -eux; \
    \
    # Download Wordpress
    wp --allow-root core download; \
    rm -r /home/www-data; \
    \
    # Delete standard stuff
    rm -r ./wp-content \
          ./wp-config-sample.php; \
    \
    # Redownload latest theme
    wp-theme-install twentytwenty; \
    mkdir -p /skeleton/wp-content/themes/; \
    cp -r ./wp-content /skeleton/; \
    \
    # Fix permission
    chown www-data:www-data -R .; \
    find . -type d -exec chmod 755 {} \;; \
    find . -type f -exec chmod 644 {} \;

VOLUME ["/data"]

# https://github.com/renatomefi/php-fpm-healthcheck
RUN curl -fsSL -o /usr/local/bin/php-fpm-healthcheck https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck; \
    chmod +x /usr/local/bin/php-fpm-healthcheck; \
    echo 'pm.status_path = /status' >> /usr/local/etc/php-fpm.d/zz-docker.conf
HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD ["php-fpm-healthcheck"]

COPY php/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
ENTRYPOINT ["docker-entrypoint"]
CMD ["php-fpm"]

# -----------
# Nginx stage
# -----------
# Depends on the "php" stage above
FROM nginx:${NGINX_VERSION}-alpine AS nginx

WORKDIR /app

COPY --from=php /app/ ./

COPY nginx/nginx.conf       /etc/nginx/nginx.template
COPY nginx/default.conf     /etc/nginx/conf.d/default.template
COPY nginx/default-ssl.conf /etc/nginx/conf.d/default-ssl.template

RUN set -eux; \
    \
    apk update; \
    apk add --no-cache \
        bash \
        openssl; \
    \
    # Remove default config, will be replaced on startup with custom one
    rm /etc/nginx/conf.d/default.conf; \
    \
    # Empty all php files (to reduce container size). Only the file's existence is important
    find . -type f -name "*.php" -exec sh -c 'i="$1"; >"$i"' _ {} \;; \
    \
    # Fix permission
    adduser -u 82 -D -S -G www-data www-data

VOLUME ["/data"]

HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD ["test", "-e", "/var/run/nginx.pid", "||", "exit", "1"]

COPY nginx/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
ENTRYPOINT ["docker-entrypoint"]
CMD ["nginx", "-g", "daemon off;"]
