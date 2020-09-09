#!/bin/bash

# Reference: https://wordpress.stackexchange.com/questions/17130/how-can-i-create-a-bash-install-script-for-my-wordpress-sites-setup-wpplugins/219429#219429

set -eo pipefail

quiet=
echo_log() {
    local type="$1"
    shift
    [ ! "$quiet" ] && printf '[%s]: %s\n' "$type" "$*" || return 0
}
echo_note() {
    echo_log Note "$@"
}
echo_warn() {
    echo_log Warn "$@" >&2
}
echo_error() {
    echo_log ERROR "$@" >&2
    exit 1
}

usage() {
    echo "usage: $0 [options] plugin-name [plugin-name ...]"
    echo "   ie: $0 jetpack"
    echo "       $0 -q jetpack woocommerce"
    echo
	echo 'Possible values for options:'
    echo '  -?|-h|--help  Opens help page'
    echo '  -q|--quiet    Mutes notes'
}

opts="$(getopt -o 'h?q' -l 'help,quiet' -- "$@" || { usage >&2 && false; })"
eval set -- "$opts"

while true; do
    flag="$1"
    shift
    case "$flag" in
    --help | -h | '-?')
        usage
        exit 0
        ;;
    --quiet | -q)
        quiet=1
        ;;
    --)
        break
        ;;
    *)
        {
            echo "error: unknown flag: $flag"
            usage
        } >&2
        exit 1
        ;;
    esac
done

plugins=
for plugin; do
    if [ -z "$plugin" ]; then
        continue
    fi
    plugins="$plugins $plugin"
done

if [ -z "$plugins" ]; then
    echo 'No plugin names supplied. Need at least one'
    echo
    usage >&2
    exit 1
fi

for plugin in $plugins; do
    FOLDER="$PWD/wp-content/plugins"
    if [ ! -d "$FOLDER" ]; then
        mkdir -p "$FOLDER"
    fi
    NAME="$(echo "$plugin" | cut -d':' -f1)"
    VERSION="$(echo "$plugin" | cut -d':' -f2)"
    [ "$VERSION" = "$NAME" ] && VERSION=latest-stable

    echo_note "Downloading $NAME from https://downloads.wordpress.org/plugin/$NAME.$VERSION.zip ..."
    curl -fsSL -o "/tmp/$NAME.$VERSION.zip" "https://downloads.wordpress.org/plugin/$NAME.$VERSION.zip"

    echo_note "Installing $NAME ..."
    unzip -q "/tmp/$NAME.$VERSION.zip" -d "$FOLDER"
    rm "/tmp/$NAME.$VERSION.zip"
done
