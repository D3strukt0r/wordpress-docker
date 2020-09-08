#!/bin/sh

set -e

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
    set -- nginx "$@"
fi

# Prepare nginx
if [ "$1" = 'nginx' ]; then
    # https://github.com/docker-library/docs/issues/496#issuecomment-287927576
    envsubst "$(printf '${%s} ' $(bash -c "compgen -A variable"))" </etc/nginx/nginx.template >/etc/nginx/nginx.conf
    if [ "$USE_HTTPS" = 'true' ]; then
        if [ ! -f '/certs/website.crt' ] || [ ! -f '/certs/website.key' ]; then
            if [ ! -d '/certs' ]; then
                mkdir /certs
            fi
            cd /certs

            echo 'Creating SSL certificate ...'
            openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out website.crt -keyout website.key -subj "/C=/ST=/L=/O=/OU=/CN="
        fi

        # Link files
        echo 'Linking certificates to /etc/ssl/certs/* ...'
        ln -sf /certs/website.crt /etc/ssl/certs/website.crt
        ln -sf /certs/website.key /etc/ssl/certs/website.key

        echo 'Enabling HTTPS for nginx ...'
        if [ ! -f '/etc/nginx/conf.d/default-ssl.conf' ]; then
            envsubst "$(printf '${%s} ' $(bash -c "compgen -A variable"))" </etc/nginx/conf.d/default-ssl.template >/etc/nginx/conf.d/default-ssl.conf
        fi
    else
        echo 'Enabling HTTP for nginx ...'
        envsubst "$(printf '${%s} ' $(bash -c "compgen -A variable"))" </etc/nginx/conf.d/default.template >/etc/nginx/conf.d/default.conf
    fi
fi

exec /docker-entrypoint.sh "$@"
