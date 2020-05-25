#!/bin/bash

set -eux

# Get necessary software
apk update
apk add --no-cache bash-completion sed curl unzip
/build/install-wp-cli.sh

# Setup some recommended variables for Wordpress
{
    echo 'error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR'
    echo 'display_errors = Off'
    echo 'display_startup_errors = Off'
    echo 'log_errors = On'
    echo 'error_log = /dev/stderr'
    echo 'log_errors_max_len = 1024'
    echo 'ignore_repeated_errors = On'
    echo 'ignore_repeated_source = Off'
    echo 'html_errors = Off'
} >"$PHP_INI_DIR"/conf.d/error-logging.ini

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
