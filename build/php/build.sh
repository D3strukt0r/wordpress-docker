#!/bin/bash

set -eux

# Alpine package for "imagemagick" contains ~120 .so files, see: https://github.com/docker-library/wordpress/pull/497
apk add --no-cache imagemagick
# shellcheck disable=SC2086
apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    freetype-dev libjpeg-turbo-dev libpng-dev \
    gettext-dev \
    imap-dev \
    icu-dev \
    libzip-dev \
    imagemagick-dev
docker-php-ext-configure gd --with-freetype --with-jpeg >/dev/null
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
    >/dev/null
pecl install imagick >/dev/null
docker-php-ext-enable imagick

# Find packages to keep, so we can safely delete dev packages
RUN_DEPS="$(
    scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions |
        tr ',' '\n' |
        sort -u |
        awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }'
)"
# shellcheck disable=SC2086
apk add --virtual .phpexts-rundeps $RUN_DEPS

# Remove building tools for smaller container size
rm -rf /tmp/pear
apk del .build-deps

# Get necessary software
/build/install-wp-cli.sh

# Download Wordpress
mkdir /app
cd /app
if [[ ! -f "/build/wordpress.tar.gz" ]]; then
    wp --allow-root core download

    # Delete download cache
    rm -r /home/www-data
else
    # In case you downloaded and put the wordpress file under /build/php/wordpress.tar.gz manually
    tar --strip-components=1 -xzf /build/wordpress.tar.gz
fi

# Delete standard stuff
rm -r ./wp-content \
    ./wp-config-sample.php

# Fix permission
chown www-data:www-data -R .
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;

# Start installing into skeleton
mkdir /skeleton
cd /skeleton

# Save custom config
mv /build/wp-config.php .

# Redownload latest theme
wp-theme-install.sh twentytwenty

# Cleanup
rm -r /build
