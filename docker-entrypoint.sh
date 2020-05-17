#!/bin/bash

UPLOAD_LIMIT_INI_FILE="$PHP_INI_DIR/conf.d/upload-limit.ini"
if [[ ! -z "${UPLOAD_LIMIT}" ]]; then
    echo "Adding the custom upload limit."
    echo -e "upload_max_filesize = $UPLOAD_LIMIT\npost_max_size = $UPLOAD_LIMIT\n" > $UPLOAD_LIMIT_INI_FILE
fi

exec "$@"
