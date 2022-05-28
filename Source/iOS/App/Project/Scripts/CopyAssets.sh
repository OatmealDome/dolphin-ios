#!/bin/bash

set -e

XCASSETS_DIR="$PROJECT_DIR/Common/DolphinAssets.xcassets"

ROOT_DOLPHIN_DIR="$PROJECT_DIR/../../.."
ANDROID_RES_DIR="$ROOT_DOLPHIN_DIR/Source/Android/app/src/main/res"
ONEX_DIR="$ANDROID_RES_DIR/drawable-hdpi"
TWOX_DIR="$ANDROID_RES_DIR/drawable-xhdpi"
THREEX_DIR="$ANDROID_RES_DIR/drawable-xxhdpi"

# Clear all images
rm -rf "$XCASSETS_DIR/"*.imageset

for path in "$ONEX_DIR/"*
do
  FILENAME=$(basename "$path" .png)
  
  mkdir "$XCASSETS_DIR/$FILENAME.imageset"
  
  cp "$ONEX_DIR/$FILENAME.png" "$XCASSETS_DIR/$FILENAME.imageset/$FILENAME@1x.png"
  cp "$TWOX_DIR/$FILENAME.png" "$XCASSETS_DIR/$FILENAME.imageset/$FILENAME@2x.png"
  cp "$THREEX_DIR/$FILENAME.png" "$XCASSETS_DIR/$FILENAME.imageset/$FILENAME@3x.png"
  
  sed "s/FILENAME/$FILENAME/g" "$PROJECT_DIR/Project/Templates/ImageAsset.json.in" > "$XCASSETS_DIR/$FILENAME.imageset/Contents.json"
done
