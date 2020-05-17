#!/bin/bash

# Output
set -ex

# Create default folders
mkdir /app
mkdir /data

# Set entrypoint
cd /tmp/app
mv docker-entrypoint.sh /usr/local/bin

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
} > /usr/local/etc/php/conf.d/error-logging.ini

# Download Wordpress
if [[ ! -f "wordpress.tar.gz" ]]; then
    curl -o wordpress.tar.gz -fSL "https://wordpress.org/latest.tar.gz"
fi
tar -xzf wordpress.tar.gz

# Save to /app
mv wordpress/* /app
rm -r /tmp/app

# Delete standard stuff
cd /app
rm -r ./wp-content/plugins/akismet ./wp-content/plugins/hello.php
rm -r ./wp-content/themes/twentyseventeen ./wp-content/themes/twentynineteen

# Link wp-config.php
mv ./wp-config-sample.php /data/wp-config.php
ln -s /data/wp-config.php ./wp-config.php

# Link wp-content/
mv ./wp-content /data/wp-content
ln -s /data/wp-content ./wp-content

# Fix permissions
chown -R www-data:www-data /app
chown -R www-data:www-data /data
