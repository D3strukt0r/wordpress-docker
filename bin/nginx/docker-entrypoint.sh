#!/usr/bin/env bash

set -eux

cd /app

# Empty all app files (to reduce size). Only the file's existence is important
# find . -type f -exec sh -c '>"{}"' \;

# Create wp-config.php
if [[ ! -f "/data/wp-config.php" ]]; then
    touch ./wp-config.php
fi

# Link wp-config.php
if [[ ! -L "./wp-config.php" ]]; then
    if [[ -f "/data/wp-config.php" ]]; then
        if [[ -f "./wp-config.php" ]]; then
            rm ./wp-config.php
        fi
        ln -s /data/wp-config.php ./wp-config.php
    fi
fi

# Prepare wp-content/
if [[ ! -d "/data/wp-content/themes" ]]; then
    mkdir -p /data/wp-content/themes
fi
if [[ "$(find /data/wp-content/themes -maxdepth 1 -type d | wc -l)" -eq 1 ]]; then
    cp -r /skeleton/wp-content/themes/twentytwenty /data/wp-content/themes
fi
if [[ ! -d "/data/wp-content/plugins" ]]; then
    mkdir -p /data/wp-content/plugins
fi
if [[ "$(find /data/wp-content/plugins -maxdepth 1 -type d | wc -l)" -eq 1 && -d "/skeleton/wp-content/plugins" ]]; then
    cp -r /skeleton/wp-content/plugins/* /data/wp-content/plugins
fi

# Link wp-content/
if [[ ! -L "./wp-content" ]]; then
    if [[ -d "/data/wp-content" ]]; then
        if [[ -f "./wp-content" ]]; then
            rm ./wp-content
        fi
        ln -s /data/wp-content ./wp-content
    fi
fi

exec "$@"
