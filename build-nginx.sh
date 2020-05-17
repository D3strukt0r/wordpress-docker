#!/bin/bash

# Output
set -ex

mkdir /data/web -p
mv ./web/cpresources /data/web
ln -s /data/web/cpresources ./web/cpresources

# Link wp-config.php
mv ./wp-config-sample.php /data/wp-config.php
ln -s /data/wp-config.php ./wp-config.php

# Link wp-content/
mv ./wp-content /data/wp-content
ln -s /data/wp-content ./wp-content

# Fix permissions
chown -R www-data:www-data /app
chown -R www-data:www-data /data
