#!/bin/bash

set -eo pipefail

# If command starts with an option (`-f` or `--some-option`), prepend main command
if [ "${1#-}" != "$1" ]; then
    set -- nginx "$@"
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

# Prepare nginx
if [ "$1" = 'nginx' ]; then
    entrypoint_note 'Entrypoint script for Wordpress started'

    # ----------------------------------------

    entrypoint_note 'Load various environment variables'
    envs=(
        NGINX_CLIENT_MAX_BODY_SIZE
        USE_HTTPS
    )

    # Set empty environment variable or get content from "/run/secrets/<something>"
    for e in "${envs[@]}"; do
        file_env "$e"
    done

    # Important for upload limit.
    : "${NGINX_CLIENT_MAX_BODY_SIZE:=100M}"

    : "${USE_HTTPS:=false}"

    # ----------------------------------------

    # https://github.com/docker-library/docs/issues/496#issuecomment-287927576
    envsubst "$(printf '${%s} ' $(bash -c "compgen -A variable"))" </etc/nginx/nginx.template >/etc/nginx/nginx.conf
    if [ "$USE_HTTPS" = 'true' ]; then
        if [ ! -f /certs/website.crt ] || [ ! -f /certs/website.key ]; then
            if [ ! -d /certs ]; then
                mkdir /certs
            fi
            cd /certs

            echo 'Creating SSL certificate ...'
            openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out website.crt -keyout website.key -subj '/C=/ST=/L=/O=/OU=/CN='
        fi

        # Link files
        echo 'Linking certificates to /etc/ssl/certs/* ...'
        ln -sf /certs/website.crt /etc/ssl/certs/website.crt
        ln -sf /certs/website.key /etc/ssl/certs/website.key

        echo 'Enabling HTTPS for nginx ...'
        if [ ! -f /etc/nginx/conf.d/default-ssl.conf ]; then
            envsubst "$(printf '${%s} ' $(bash -c "compgen -A variable"))" </etc/nginx/conf.d/default-ssl.template >/etc/nginx/conf.d/default-ssl.conf
        fi
    else
        echo 'Enabling HTTP for nginx ...'
        envsubst "$(printf '${%s} ' $(bash -c "compgen -A variable"))" </etc/nginx/conf.d/default.template >/etc/nginx/conf.d/default.conf
    fi
fi

exec /docker-entrypoint.sh "$@"
