FROM d3strukt0r/php-wordpress AS php

WORKDIR /tmp/app
COPY . .
RUN /tmp/app/build.sh

VOLUME [ "/data" ]

ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD [ "php-fpm" ]
