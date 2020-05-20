#!/bin/bash

set -eux

cd /app

# Empty all app files (to reduce size). Only the file's existence is important
find . -type f -exec sh -c '>"{}"' \;

# Link wp-config.php
if [[ -f "/data/wp-config.php" ]]; then
    ln -sf /data/wp-config.php ./wp-config.php
fi

# Link wp-content/
if [[ -d "/data/wp-content" ]]; then
    ln -sf /data/wp-content ./wp-content
fi

exec "$@"
