#!/bin/bash

set -e

BASE_DIR=$(mktemp -d)

echo "Temporary directory at $BASE_DIR"

APP_BUNDLE_PATH=$1
SIGNING_CERTIFICATE=$2
ENTITLEMENTS_PATH=$3
CONTROL_PATH=$4
POSTINST_PATH=$5
POSTRM_PATH=$6
APP_INSTALLATION_DESTINATION=$7
OUTPUT_FILE=$8

VERSION_STRING=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP_BUNDLE_PATH/Info.plist")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$APP_BUNDLE_PATH/Info.plist")

mkdir "$BASE_DIR/$APP_INSTALLATION_DESTINATION"

# As recommended by saurik, don't copy dot files
export COPYFILE_DISABLE
export COPY_EXTENDED_ATTRIBUTES_DISABLE

cp -R "$APP_BUNDLE_PATH" "$BASE_DIR/$APP_INSTALLATION_DESTINATION"

# Sign in two steps: frameworks, and then the main executable
codesign -f -s "$SIGNING_CERTIFICATE" "$BASE_DIR/$APP_INSTALLATION_DESTINATION/DolphiniOS.app/Frameworks/"*
codesign -f -s "$SIGNING_CERTIFICATE" --entitlements "$ENTITLEMENTS_PATH" "$BASE_DIR/$APP_INSTALLATION_DESTINATION/DolphiniOS.app"

mkdir "$BASE_DIR/DEBIAN"

cp "$POSTINST_PATH" "$BASE_DIR/DEBIAN/postinst"
cp "$POSTRM_PATH" "$BASE_DIR/DEBIAN/postrm"

chmod -R 755 "$BASE_DIR/DEBIAN/"*

sed "s/VERSION_NUMBER/$VERSION_STRING-$BUILD_NUMBER/g" "$CONTROL_PATH" > "$BASE_DIR/DEBIAN/control"

dpkg-deb -b "$BASE_DIR" "$OUTPUT_FILE"

echo "Cleaning up"

rm -rf "$BASE_DIR"

echo "Done"
