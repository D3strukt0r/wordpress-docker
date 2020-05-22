#!/bin/bash

set -eux

# Use default config for nginx
mv /build/nginx.conf /etc/nginx/nginx.template
mv /build/default.conf /etc/nginx/conf.d/default.template
mv /build/default-ssl.conf /etc/nginx/conf.d/default-ssl.template

# Cleanup
rm -r /build
