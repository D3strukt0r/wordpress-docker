#!/bin/sh

# Reference: https://wordpress.stackexchange.com/questions/17130/how-can-i-create-a-bash-install-script-for-my-wordpress-sites-setup-wpplugins/219429#219429

set -e

if [ $# = 0 ]; then
    echo "No arguments supplied. Need at least one with the plugin name"
    exit 1
fi

PLUGINS_FOLDER="$PWD/wp-content/plugins"

if [ ! -d "$PLUGINS_FOLDER" ]; then
    mkdir -p "$PLUGINS_FOLDER"
fi

PLUGIN_NAME="$1"
PLUGIN_VERSION="${2:-latest-stable}"

echo "Downloading $PLUGIN_NAME from https://downloads.wordpress.org/plugin/$PLUGIN_NAME.$PLUGIN_VERSION.zip ..."
curl -fsSL -o "/tmp/$PLUGIN_NAME.$PLUGIN_VERSION.zip" "https://downloads.wordpress.org/plugin/$PLUGIN_NAME.$PLUGIN_VERSION.zip"

echo "Installing $PLUGIN_NAME ..."
unzip -q "/tmp/$PLUGIN_NAME.$PLUGIN_VERSION.zip" -d "$PLUGINS_FOLDER"
rm "/tmp/$PLUGIN_NAME.$PLUGIN_VERSION.zip"
