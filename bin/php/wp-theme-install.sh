#!/usr/bin/env bash

# Reference: https://wordpress.stackexchange.com/questions/17130/how-can-i-create-a-bash-install-script-for-my-wordpress-sites-setup-wpplugins/219429#219429

set -eu

if [[ $# -eq 0 ]]; then
    echo "No arguments supplied. Need at least one with the plugin name"
    exit 1
fi

THEMES_FOLDER=$PWD/wp-content/themes

if [[ ! -d $THEMES_FOLDER ]]; then
    mkdir -p "$THEMES_FOLDER"
fi

THEME_NAME=$1
THEME_VERSION=${2:-latest-stable}

echo "Downloading $THEME_NAME from https://downloads.wordpress.org/theme/$THEME_NAME.$THEME_VERSION.zip ..."
curl -fsSL -o "/tmp/$THEME_NAME.$THEME_VERSION.zip" "https://downloads.wordpress.org/theme/$THEME_NAME.$THEME_VERSION.zip"

echo "Installing $THEME_NAME ..."
unzip -q "/tmp/$THEME_NAME.$THEME_VERSION.zip" -d "$THEMES_FOLDER"
rm "/tmp/$THEME_NAME.$THEME_VERSION.zip"
