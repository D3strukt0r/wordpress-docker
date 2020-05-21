#!/usr/bin/env bash

# Use default config for nginx
mv /build/default.conf /etc/nginx/conf.d/default.template
mv /build/default-ssl.conf /etc/nginx/conf.d/default-ssl.template

# Cleanup
rm -r /build
