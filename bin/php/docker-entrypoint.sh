#!/usr/bin/env bash

set -eux

cd /app

# TODO: See what to do with following code:
# # https://github.com/docker-library/wordpress/blob/8215003254de4bf0a8ddd717c3c393e778b872ce/php7.4/fpm-alpine/docker-entrypoint.sh
# # usage: file_env VAR [DEFAULT]
# #   ie: file_env 'XYZ_DB_PASSWORD' 'example'
# #(will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
# # "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
# file_env() {
#     local var="$1"
#     local fileVar="${var}_FILE"
#     local def="${2:-}"
#     if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
#         echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
#         exit 1
#     fi
#     local val="$def"
#     if [ "${!var:-}" ]; then
#         val="${!var}"
#     elif [ "${!fileVar:-}" ]; then
#         val="$(< "${!fileVar}")"
#     fi
#     export "$var"="$val"
#     unset "$fileVar"
# }

# # allow any of these "Authentication Unique Keys and Salts." to be specified via
# # environment variables with a "WORDPRESS_" prefix (ie, "WORDPRESS_AUTH_KEY")
# uniqueEnvs=(
#     AUTH_KEY
#     SECURE_AUTH_KEY
#     LOGGED_IN_KEY
#     NONCE_KEY
#     AUTH_SALT
#     SECURE_AUTH_SALT
#     LOGGED_IN_SALT
#     NONCE_SALT
# )
# envs=(
#     WORDPRESS_DB_HOST
#     WORDPRESS_DB_USER
#     WORDPRESS_DB_PASSWORD
#     WORDPRESS_DB_NAME
#     WORDPRESS_DB_CHARSET
#     WORDPRESS_DB_COLLATE
#     "${uniqueEnvs[@]/#/WORDPRESS_}"
#     WORDPRESS_TABLE_PREFIX
#     WORDPRESS_DEBUG
#     WORDPRESS_CONFIG_EXTRA
# )
# haveConfig=
# for e in "${envs[@]}"; do
#     file_env "$e"
#     if [ -z "$haveConfig" ] && [ -n "${!e}" ]; then
#         haveConfig=1
#     fi
# done

# Set upload limit
if [[ -n "$UPLOAD_LIMIT" ]]; then
    echo "Adding the custom upload limit."
    {
        echo "upload_max_filesize = $UPLOAD_LIMIT"
        echo "post_max_size = $UPLOAD_LIMIT"
    } > "$PHP_INI_DIR/conf.d/upload-limit.ini"
fi

# Create wp-config.php
if [[ ! -f "/data/wp-config.php" ]]; then
    wp --allow-root config create \
        --dbhost="$DB_HOST:$DB_PORT" \
        --dbuser="$DB_USER" \
        --dbpass="$DB_PASSWORD" \
        --dbname="$DB_NAME" \
        --dbcharset="$DB_CHARSET" \
        --dbcollate="$DB_COLLATE" \
        --skip-check
    mv ./wp-config.php /data
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

# Fix permission
chown -R www-data:www-data /data
find /data -type d -exec chmod 755 {} \;
find /data -type f -exec chmod 644 {} \;

exec "$@"