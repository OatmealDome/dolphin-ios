#!/bin/bash

set -e

BASE_DIR=$(mktemp -d)
CURRENT_DIR=$(pwd)

echo "Temporary directory at $BASE_DIR"

APP_BUNDLE_PATH=$1
SIGNING_CERTIFICATE=$2
ENTITLEMENTS_PATH=$3
OUTPUT_FILE=$4

mkdir "$BASE_DIR/Payload"

cp -R "$APP_BUNDLE_PATH" "$BASE_DIR/Payload/"

# Sign in two steps: frameworks, and then the main executable
codesign -f -s "$SIGNING_CERTIFICATE" "$BASE_DIR/Payload/DolphiniOS.app/Frameworks/"*
codesign -f -s "$SIGNING_CERTIFICATE" --entitlements "$ENTITLEMENTS_PATH" "$BASE_DIR/Payload/DolphiniOS.app"

cd "$BASE_DIR"

zip -r "$OUTPUT_FILE" .

cd "$CURRENT_DIR"

echo "Cleaning up"

rm -rf "$BASE_DIR"

echo "Done"
