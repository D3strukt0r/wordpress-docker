#!/bin/bash

set -eu

cd /app

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
    echo head -c1m /dev/urandom | sha1sum | cut -d' ' -f1
}

# Set upload limit
if [[ -n "$UPLOAD_LIMIT" ]]; then
    echo "Adding the custom upload limit of $UPLOAD_LIMIT ..."
    {
        echo "upload_max_filesize = $UPLOAD_LIMIT"
        echo "post_max_size = $UPLOAD_LIMIT"
    } >"$PHP_INI_DIR/conf.d/upload-limit.ini"
fi

# Check if database is available
if ! php /usr/local/bin/test-db-connection.php; then
    echo >&2
    echo >&2 "WARNING: unable to establish a database connection to '$DB_HOST:$DB_PORT'"
    echo >&2 '  continuing anyways (which might have unexpected results)'
    echo >&2
else
    echo "Connection to database available"
fi

# Link wp-config.php
if [[ ! -f "/data/wp-config.php" ]]; then
    # Check for available salts
    MISSING_SALT=false
    if [[ -z $WP_AUTH_KEY ]]; then
        MISSING_SALT=true
        echo "WP_AUTH_KEY=$(generate_salt)"
    fi
    if [[ -z $WP_SECURE_AUTH_KEY ]]; then
        MISSING_SALT=true
        echo "WP_SECURE_AUTH_KEY=$(generate_salt)"
    fi
    if [[ -z $WP_LOGGED_IN_KEY ]]; then
        MISSING_SALT=true
        echo "WP_LOGGED_IN_KEY=$(generate_salt)"
    fi
    if [[ -z $WP_NONCE_KEY ]]; then
        MISSING_SALT=true
        echo "WP_NONCE_KEY=$(generate_salt)"
    fi
    if [[ -z $WP_AUTH_SALT ]]; then
        MISSING_SALT=true
        echo "WP_AUTH_SALT=$(generate_salt)"
    fi
    if [[ -z $WP_SECURE_AUTH_SALT ]]; then
        MISSING_SALT=true
        echo "WP_SECURE_AUTH_SALT=$(generate_salt)"
    fi
    if [[ -z $WP_LOGGED_IN_SALT ]]; then
        MISSING_SALT=true
        echo "WP_LOGGED_IN_SALT=$(generate_salt)"
    fi
    if [[ -z $WP_NONCE_SALT ]]; then
        MISSING_SALT=true
        echo "WP_NONCE_SALT=$(generate_salt)"
    fi
    if [[ $MISSING_SALT == "true" ]]; then
        echo "You seem not to have set some required variables. Please take a look"
        echo "at the ones given above for you to use or visit:"
        echo "https://api.wordpress.org/secret-key/1.1/salt/"
        exit 1
    fi

    echo "Linking wp-config.php in /skeleton ..."
    if [[ -f "./wp-config.php" ]]; then
        rm ./wp-config.php
    fi
    ln -s /skeleton/wp-config.php ./wp-config.php
else
    echo "Linking wp-config.php from /data to /app ..."
    if [[ -f "./wp-config.php" ]]; then
        rm ./wp-config.php
    fi
    ln -s /data/wp-config.php ./wp-config.php
fi

# Prepare wp-content/
if [[ ! -d "/data/wp-content/themes" ]]; then
    mkdir -p /data/wp-content/themes
fi
if [[ "$(find /data/wp-content/themes -maxdepth 1 -type d | wc -l)" -eq 1 ]]; then
    echo "Copying themes from skeleton ..."
    cp -r /skeleton/wp-content/themes/* /data/wp-content/themes
fi
if [[ ! -d "/data/wp-content/plugins" ]]; then
    mkdir -p /data/wp-content/plugins
fi
if [[ "$(find /data/wp-content/plugins -maxdepth 1 -type d | wc -l)" -eq 1 && -d "/skeleton/wp-content/plugins" ]]; then
    echo "Copying plugins from skeleton ..."
    cp -r /skeleton/wp-content/plugins/* /data/wp-content/plugins
fi

# Link wp-content/
if [[ ! -L "./wp-content" ]]; then
    if [[ -d "/data/wp-content" ]]; then
        if [[ -f "./wp-content" ]]; then
            rm ./wp-content
        fi
        echo "Linking wp-content/ from /data to /app ..."
        ln -s /data/wp-content ./wp-content
    fi
fi

# Fix permission
echo "Fixing permission in /data to fit php-fpm ..."
chown -R www-data:www-data /data
find /data -type d -exec chmod 755 {} \;
find /data -type f -exec chmod 644 {} \;

exec "$@"
