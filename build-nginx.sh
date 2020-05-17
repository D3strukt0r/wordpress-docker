#!/bin/bash

# Output
set -ex

# Use default config for nginx
mv /tmp/app/default-nginx.conf /etc/nginx/conf.d/default.conf

# Link wp-config.php
cd /app
ln -sf /data/wp-config.php ./wp-config.php

# Link wp-content/
ln -s /data/wp-content ./wp-content

# Fix permissions
chown -R nginx:nginx /app
chown -R nginx:nginx /data
