# ---------
# PHP stage
# ---------
FROM d3strukt0r/php-wordpress AS php

WORKDIR /tmp/app
COPY . .
RUN /tmp/app/build-php.sh

VOLUME [ "/data" ]

ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD [ "php-fpm" ]

# -----------
# Nginx stage
# -----------
FROM nginx:1.17-alpine AS nginx

# Copy all the source files
WORKDIR /tmp/app
COPY build-nginx.sh .
COPY default-nginx.conf .
COPY --from=php /app /app
COPY --from=php /data /data
RUN set -ex; \
apk update; \
apk add --no-cache bash nano; \
./build-nginx.sh

VOLUME [ "/data" ]
