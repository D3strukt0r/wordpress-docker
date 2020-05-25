# ---------
# PHP stage
# ---------
FROM d3strukt0r/php-wordpress AS php

COPY bin/php /usr/local/bin
COPY build/php /build

RUN set -eux; \
    apk update; \
    apk add --no-cache bash nano; \
    /build/build.sh

VOLUME [ "/data" ]

ENV UPLOAD_LIMIT= \
    DB_HOST=db \
    DB_PORT=3306 \
    DB_USER=root \
    DB_PASSWORD= \
    DB_NAME=wordpress \
    DB_CHARSET=utf8mb4 \
    DB_COLLATE=utf8mb4_unicode_ci \
    DB_TABLE_PREFIX=wp_ \
    WP_AUTH_KEY= \
    WP_SECURE_AUTH_KEY= \
    WP_LOGGED_IN_KEY= \
    WP_NONCE_KEY= \
    WP_AUTH_SALT= \
    WP_SECURE_AUTH_SALT= \
    WP_LOGGED_IN_SALT= \
    WP_NONCE_SALT= \
    WP_DEBUG=false

ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD [ "php-fpm" ]

# -----------
# Nginx stage
# -----------
FROM nginx:stable-alpine AS nginx

COPY bin/nginx /usr/local/bin
COPY build/nginx /build

COPY --from=php /app /app
COPY --from=php /skeleton /skeleton

RUN set -eux; \
    apk update; \
    apk add --no-cache bash nano openssl; \
    /build/build.sh

VOLUME [ "/data" ]

ENV UPLOAD_LIMIT=100M \
    USE_HTTP=false

ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD ["nginx", "-g", "daemon off;"]
