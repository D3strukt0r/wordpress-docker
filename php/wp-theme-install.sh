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
    echo "usage: $0 [-q] theme-name [theme-name ...]"
    echo "   ie: $0 customify"
    echo "       $0 -q customify twentynineteen"
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

themes=
for theme; do
    if [ -z "$theme" ]; then
        continue
    fi
    themes="$themes $theme"
done

if [ -z "$themes" ]; then
    echo 'No theme names supplied. Need at least one'
    echo
    usage >&2
    exit 1
fi

for theme in $themes; do
    FOLDER="$PWD/wp-content/themes"
    if [ ! -d "$FOLDER" ]; then
        mkdir -p "$FOLDER"
    fi
    NAME="$(echo "$theme" | cut -d':' -f1)"
    VERSION="$(echo "$theme" | cut -d':' -f2)"
    [ "$VERSION" = "$NAME" ] && VERSION=latest-stable

    echo_note "Downloading $NAME from https://downloads.wordpress.org/theme/$NAME.$VERSION.zip ..."
    curl -fsSL -o "/tmp/$NAME.$VERSION.zip" "https://downloads.wordpress.org/theme/$NAME.$VERSION.zip"

    echo_note "Installing $NAME ..."
    unzip -q "/tmp/$NAME.$VERSION.zip" -d "$FOLDER"
    rm "/tmp/$NAME.$VERSION.zip"
done
