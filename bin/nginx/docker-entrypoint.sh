#!/usr/bin/env bash

set -eux

cd /app

# Empty all app files (to reduce size). Only the file's existence is important
# find . -type f -exec sh -c '>"{}"' \;

# Link wp-config.php
if [[ ! -L "./wp-config.php" ]]; then
    if [[ -f "/data/wp-config.php" ]]; then
        if [[ -f "./wp-config.php" ]]; then
            rm ./wp-config.php
        fi
        ln -s /data/wp-config.php ./wp-config.php
    fi
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
