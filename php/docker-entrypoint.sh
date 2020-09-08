#!/bin/bash

set -e

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
    set -- php-fpm "$@"
fi

# Setup php
if [ "$1" = 'php-fpm' ] || [ "$1" = 'php' ]; then
    # usage: file_env VAR [DEFAULT]
    #   ie: file_env 'XYZ_DB_PASSWORD' 'example'
    #(will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
    # "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
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

    generate_salt() {
        head -c1m /dev/urandom | sha1sum | cut -d' ' -f1
    }

    # ----------------------------------------

    echo 'Load/Create optimized PHP configs ...'

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
        echo 'Update CA certificates ...'
        ln -sf /certs/localCA.crt /usr/local/share/ca-certificates/localCA.crt
        update-ca-certificates
    fi

    # ----------------------------------------

    echo 'Waiting for db to be ready...'

    ATTEMPTS_LEFT_TO_REACH_DATABASE=60
    until [ $ATTEMPTS_LEFT_TO_REACH_DATABASE = 0 ] || mysql --host="$DB_HOST" --port="$DB_PORT" --user="$DB_USER" --password="$DB_PASSWORD" -e 'SELECT 1' >/dev/null 2>&1; do
        sleep 1
        ATTEMPTS_LEFT_TO_REACH_DATABASE=$((ATTEMPTS_LEFT_TO_REACH_DATABASE - 1))
        echo "Still waiting for db to be ready... Or maybe the db is not reachable. $ATTEMPTS_LEFT_TO_REACH_DATABASE attempts left"
    done

    if [ $ATTEMPTS_LEFT_TO_REACH_DATABASE = 0 ]; then
        echo 'The db is not up or not reachable'
        exit 1
    else
        echo 'The db is now ready and reachable'
    fi

    # ----------------------------------------

    # Check for available salts
    MISSING_SALT=false
    if [ -z "$WP_AUTH_KEY" ]; then
        MISSING_SALT=true
        echo "WP_AUTH_KEY=$(generate_salt)"
    fi
    if [ -z "$WP_SECURE_AUTH_KEY" ]; then
        MISSING_SALT=true
        echo "WP_SECURE_AUTH_KEY=$(generate_salt)"
    fi
    if [ -z "$WP_LOGGED_IN_KEY" ]; then
        MISSING_SALT=true
        echo "WP_LOGGED_IN_KEY=$(generate_salt)"
    fi
    if [ -z "$WP_NONCE_KEY" ]; then
        MISSING_SALT=true
        echo "WP_NONCE_KEY=$(generate_salt)"
    fi
    if [ -z "$WP_AUTH_SALT" ]; then
        MISSING_SALT=true
        echo "WP_AUTH_SALT=$(generate_salt)"
    fi
    if [ -z "$WP_SECURE_AUTH_SALT" ]; then
        MISSING_SALT=true
        echo "WP_SECURE_AUTH_SALT=$(generate_salt)"
    fi
    if [ -z "$WP_LOGGED_IN_SALT" ]; then
        MISSING_SALT=true
        echo "WP_LOGGED_IN_SALT=$(generate_salt)"
    fi
    if [ -z "$WP_NONCE_SALT" ]; then
        MISSING_SALT=true
        echo "WP_NONCE_SALT=$(generate_salt)"
    fi
    if [ "$MISSING_SALT" = 'true' ]; then
        echo 'You seem not to have set some required variables. Please take a look'
        echo 'at the ones given above for you to use or visit:'
        echo 'https://api.wordpress.org/secret-key/1.1/salt/'
        exit 1
    fi

    # ----------------------------------------

    # Wordpress requires at least one theme, make sure it's installed from skeleton
    if [ ! -d ./wp-content/themes ]; then
        mkdir -p ./wp-content/themes
    fi
    if [ "$(find ./wp-content/themes -maxdepth 1 -type d | wc -l)" = 1 ]; then
        echo 'Copying themes from skeleton ...'
        cp -r /skeleton/wp-content/themes/* ./wp-content/themes/
    fi
    # If plugins are available in skeleton, install them
    if [ ! -d ./wp-content/plugins ]; then
        mkdir -p ./wp-content/plugins
    fi
    if [ "$(find ./wp-content/plugins -maxdepth 1 -type d | wc -l)" = 1 ] && [ -d /skeleton/wp-content/plugins ]; then
        echo 'Copying plugins from skeleton ...'
        cp -r /skeleton/wp-content/plugins/* ./wp-content/plugins/
    fi

    # ----------------------------------------

    echo 'Fix directory/file permissions ...'
    chown -R www-data:www-data .
    find . -type d -exec chmod 755 {} \;
    find . -type f -exec chmod 644 {} \;
fi

exec docker-php-entrypoint "$@"
