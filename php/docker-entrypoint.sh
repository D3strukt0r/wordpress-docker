#!/bin/bash

set -eo pipefail

# If command starts with an option (`-f` or `--some-option`), prepend main command
if [ "${1#-}" != "$1" ]; then
    set -- php-fpm "$@"
fi

# Logging functions
entrypoint_log() {
    local type="$1"
    shift
    printf '%s [%s] [Entrypoint]: %s\n' "$(date '+%Y-%m-%d %T %z')" "$type" "$*"
}
entrypoint_note() {
    entrypoint_log Note "$@"
}
entrypoint_warn() {
    entrypoint_log Warn "$@" >&2
}
entrypoint_error() {
    entrypoint_log ERROR "$@" >&2
    exit 1
}

# Usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
#
# Will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
# "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature
# Read more: https://docs.docker.com/engine/swarm/secrets/
file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
        echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
    local val="$def"
    if [ "${!var:-}" ]; then
        val="${!var}"
    elif [ "${!fileVar:-}" ]; then
        val="$(<"${!fileVar}")"
    fi
    export "$var"="$val"
    unset "$fileVar"
}

# Generates a long salt
wp_generate_salt() {
    head -c1m /dev/urandom | sha1sum | cut -d' ' -f1
}

# Setup php
if [ "$1" = 'php-fpm' ] || [ "$1" = 'php' ]; then
    entrypoint_note 'Entrypoint script for Wordpress started'

    # ----------------------------------------

    entrypoint_note 'Load various environment variables'
    manualEnvs=(
        WP_AUTH_KEY
        WP_SECURE_AUTH_KEY
        WP_LOGGED_IN_KEY
        WP_NONCE_KEY
        WP_AUTH_SALT
        WP_SECURE_AUTH_SALT
        WP_LOGGED_IN_SALT
        WP_NONCE_SALT
    )
    envs=(
        PHP_MAX_EXECUTION_TIME
        PHP_MEMORY_LIMIT
        PHP_POST_MAX_SIZE
        PHP_UPLOAD_MAX_FILESIZE
        ENVIRONMENT
        DB_HOST
        DB_PORT
        DB_USER
        DB_PASSWORD
        DB_NAME
        DB_CHARSET
        DB_COLLATE
        DB_TABLE_PREFIX
        "${manualEnvs[@]}"
        WP_DEBUG
    )

    # Set empty environment variable or get content from "/run/secrets/<something>"
    for e in "${envs[@]}"; do
        file_env "$e"
    done

    # Set default environment variable values
    : "${PHP_MAX_EXECUTION_TIME:=120}"
    # 'memory_limit' has to be larger than 'post_max_size' and 'upload_max_filesize'
    : "${PHP_MEMORY_LIMIT:=256M}"
    # Important for upload limit. 'post_max_size' has to be larger than 'upload_max_filesize'
    : "${PHP_POST_MAX_SIZE:=100M}"
    : "${PHP_UPLOAD_MAX_FILESIZE:=100M}"
    # The environment Wordpress is currently running in (dev, staging, production, etc.)
    : "${ENVIRONMENT:=prod}"

    # Database settings
    : "${DB_HOST:=db}"
    : "${DB_PORT:=3306}"
    : "${DB_USER:=root}"
    : "${DB_PASSWORD:=}"
    : "${DB_NAME:=wordpress}"
    : "${DB_CHARSET:=utf8mb4}"
    : "${DB_COLLATE:=utf8mb4_unicode_ci}"
    : "${DB_TABLE_PREFIX:=wp_}"

    # Wordpress secrets
    missing_salt=
    for e in "${manualEnvs[@]}"; do
        if [ -z "${!e}" ]; then
            missing_salt=1
            : "${!e:=$(wp_generate_salt)}"
            entrypoint_warn "$e=${!e}"
        fi
    done
    if [ "$missing_salt" = 1 ]; then
        entrypoint_warn "You haven't set all the salts. Above you can copy-paste the generated ones, but make sure to use them. You can also create them yourself on https://api.wordpress.org/secret-key/1.1/salt/"
    fi
    unset missing_salt

    # Other Wordpress settings
    : "${WP_DEBUG:=false}"

    # ----------------------------------------

    entrypoint_note 'Load/Create optimized PHP configs'
    PHP_INI_RECOMMENDED="$PHP_INI_DIR/php.ini-production"
    if [ "$ENVIRONMENT" != 'prod' ]; then
        PHP_INI_RECOMMENDED="$PHP_INI_DIR/php.ini-development"
    fi
    ln -sf "$PHP_INI_RECOMMENDED" "$PHP_INI_DIR/php.ini"

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
    } >"$PHP_INI_DIR/conf.d/error-logging.ini"
    {
        echo 'opcache.revalidate_freq = 0'
        if [ "$ENVIRONMENT" = 'prod' ]; then
            echo 'opcache.validate_timestamps = 0'
        fi
        echo "opcache.max_accelerated_files = $(find -L /app -type f -print | grep -c php)"
        echo 'opcache.memory_consumption = 192'
        echo 'opcache.interned_strings_buffer = 16'
        echo 'opcache.fast_shutdown = 1'
    } >"$PHP_INI_DIR/conf.d/opcache.ini"
    {
        echo "max_execution_time = $PHP_MAX_EXECUTION_TIME"
        echo "memory_limit = $PHP_MEMORY_LIMIT"
        echo 'max_input_vars = 1000'
        echo 'max_input_time = 400'
    } >"$PHP_INI_DIR/conf.d/misc.ini"
    {
        echo "post_max_size = $PHP_POST_MAX_SIZE"
        echo "upload_max_filesize = $PHP_UPLOAD_MAX_FILESIZE"
    } >"$PHP_INI_DIR/conf.d/upload-limit.ini"

    # ----------------------------------------

    if [ "$ENVIRONMENT" != 'prod' ] && [ -f /certs/localCA.crt ]; then
        entrypoint_note 'Update CA certificates.'
        ln -sf /certs/localCA.crt /usr/local/share/ca-certificates/localCA.crt
        update-ca-certificates
    fi

    # ----------------------------------------

    entrypoint_note 'Waiting for db to be ready'
    ATTEMPTS_LEFT_TO_REACH_DATABASE=60
    until [ $ATTEMPTS_LEFT_TO_REACH_DATABASE = 0 ] || mysql --host="$DB_HOST" --port="$DB_PORT" --user="$DB_USER" --password="$DB_PASSWORD" -e 'SELECT 1' >/dev/null 2>&1; do
        sleep 1
        ATTEMPTS_LEFT_TO_REACH_DATABASE=$((ATTEMPTS_LEFT_TO_REACH_DATABASE - 1))
        entrypoint_warn "Still waiting for db to be ready... Or maybe the db is not reachable. $ATTEMPTS_LEFT_TO_REACH_DATABASE attempts left"
    done

    if [ $ATTEMPTS_LEFT_TO_REACH_DATABASE = 0 ]; then
        entrypoint_error 'The db is not up or not reachable'
    else
        entrypoint_note 'The db is now ready and reachable'
    fi

    # ----------------------------------------

    # Wordpress requires at least one theme, make sure it's installed from skeleton
    if [ ! -d ./wp-content/themes ]; then
        mkdir -p ./wp-content/themes
    fi
    if [ "$(find ./wp-content/themes -maxdepth 1 -type d | wc -l)" = 1 ]; then
        entrypoint_note 'Copy themes from skeleton'
        cp -r /skeleton/wp-content/themes/* ./wp-content/themes/
    fi
    # If plugins are available in skeleton, install them
    if [ ! -d ./wp-content/plugins ]; then
        mkdir -p ./wp-content/plugins
    fi
    if [ "$(find ./wp-content/plugins -maxdepth 1 -type d | wc -l)" = 1 ] && [ -d /skeleton/wp-content/plugins ]; then
        entrypoint_note 'Copy plugins from skeleton'
        cp -r /skeleton/wp-content/plugins/* ./wp-content/plugins/
    fi

    # ----------------------------------------

    entrypoint_note 'Fix directory/file permissions'
    chown -R www-data:www-data .
    find . -type d -exec chmod 755 {} \;
    find . -type f -exec chmod 644 {} \;
fi

exec docker-php-entrypoint "$@"
