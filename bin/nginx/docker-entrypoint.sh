#!/bin/bash

set -eu

cd /app

# Prepare nginx
# https://github.com/docker-library/docs/issues/496#issuecomment-287927576
envsubst "$(printf '${%s} ' $(bash -c "compgen -A variable"))" </etc/nginx/nginx.template >/etc/nginx/nginx.conf
if [[ $USE_HTTP == "true" ]]; then
    echo "Enabling HTTP for nginx ..."
    envsubst "$(printf '${%s} ' $(bash -c "compgen -A variable"))" </etc/nginx/conf.d/default.template >/etc/nginx/conf.d/default.conf
else
    if [[ ! -f "/data/certs/website.crt" || ! -f "/data/certs/website.key" ]]; then
        echo "Creating SSL certificate ..."
        openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out website.crt -keyout website.key -subj "/C=/ST=/L=/O=/OU=/CN="

        if [[ ! -d /data/certs ]]; then
            mkdir -p /data/certs
        fi
        mv website.crt /data/certs
        mv website.key /data/certs

        # Delete files if already exist (Docker saving files)
        if [[ -f "/etc/ssl/certs/website.crt" ]]; then
            rm /etc/ssl/certs/website.crt
        fi
        if [[ -f "/etc/ssl/certs/website.key" ]]; then
            rm /etc/ssl/certs/website.key
        fi
    fi

    # Link files
    echo "Linking certificates to /etc/ssl/certs/* ..."
    if [[ -f /etc/ssl/certs/website.crt ]]; then
        rm /etc/ssl/certs/website.crt
    fi
    if [[ -f /etc/ssl/certs/website.key ]]; then
        rm /etc/ssl/certs/website.key
    fi
    ln -s /data/certs/website.crt /etc/ssl/certs/website.crt
    ln -s /data/certs/website.key /etc/ssl/certs/website.key

    echo "Enabling HTTPS for nginx ..."
    if [[ ! -f /etc/nginx/conf.d/default-ssl.conf ]]; then
        envsubst "$(printf '${%s} ' $(bash -c "compgen -A variable"))" </etc/nginx/conf.d/default-ssl.template >/etc/nginx/conf.d/default-ssl.conf
    fi
fi

# Empty all php files (to reduce size). Only the file's existence is important
find . -type f -name "*.php" -exec sh -c 'i="$1"; >"$i"' _ {} \;

# Create wp-config.php
if [[ ! -f "/data/wp-config.php" ]]; then
    echo "Creating wp-config.php ..."
    touch ./wp-config.php
fi

# Link wp-config.php
if [[ ! -L "./wp-config.php" ]]; then
    if [[ -f "/data/wp-config.php" ]]; then
        if [[ -f "./wp-config.php" ]]; then
            rm ./wp-config.php
        fi
        echo "Linking wp-config.php from /data to /app ..."
        ln -s /data/wp-config.php ./wp-config.php
    fi
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

exec "$@"
