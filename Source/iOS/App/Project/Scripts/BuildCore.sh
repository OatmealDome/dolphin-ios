#!/bin/bash

set -e

PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"

# Linking the iOS 27.1 SDK opts the app into native iPhone Duo sizing and bars.
# Keep CI and local builds from silently producing the compatibility layout.
case "$PLATFORM_NAME" in
    iphoneos|iphonesimulator)
        DOL_SDK_VERSION="$(xcrun --sdk "$PLATFORM_NAME" --show-sdk-version)"
        IFS=. read -r DOL_SDK_MAJOR DOL_SDK_MINOR DOL_SDK_PATCH <<< "$DOL_SDK_VERSION"
        if [ "$DOL_SDK_MAJOR" -lt 27 ] || { [ "$DOL_SDK_MAJOR" -eq 27 ] && [ "${DOL_SDK_MINOR:-0}" -lt 1 ]; }; then
            echo "error: Native iPhone Duo support requires Xcode 27.1 or later with the iOS 27.1 or later SDK. Selected SDK: $DOL_SDK_VERSION"
            exit 1
        fi
        ;;
esac

REPO_ROOT_DIR="$PROJECT_DIR/../../.."
CMAKE_BUILD_DIR="$REPO_ROOT_DIR/build-$PLATFORM_NAME-$DOL_CORE_BUILD_TARGET"

MACHINE_ARCH="$(arch)"

case $PLATFORM_NAME in
    iphoneos)
        PLATFORM=OS64
        PLATFORM_DEPLOYMENT_TARGET=$IPHONEOS_DEPLOYMENT_TARGET
        ;;
    iphonesimulator)
        if [ "$MACHINE_ARCH" = "arm64" ]; then
            PLATFORM=SIMULATORARM64
        else
            PLATFORM=SIMULATOR64
        fi

        PLATFORM_DEPLOYMENT_TARGET=$IPHONEOS_DEPLOYMENT_TARGET
        ;;
    appletvos)
        PLATFORM=TVOS
        PLATFORM_DEPLOYMENT_TARGET=$TVOS_DEPLOYMENT_TARGET
        ;;
    appletvsimulator)
        PLATFORM=SIMULATOR_TVOS
        PLATFORM_DEPLOYMENT_TARGET=$TVOS_DEPLOYMENT_TARGET
        ;;
    *)
        echo "Unknown platform \"$PLATFORM_NAME\""
        exit 1
        ;;
esac

if [ ! -d "$CMAKE_BUILD_DIR" ]; then
    mkdir "$CMAKE_BUILD_DIR"
fi

cd "$CMAKE_BUILD_DIR"

if [ ! -f "$CMAKE_BUILD_DIR/build.ninja" ] || \
   ! grep -Fqx "CMAKE_CXX_FLAGS:STRING=-fPIC -DFMT_CONSTEVAL=" "$CMAKE_BUILD_DIR/CMakeCache.txt"; then
  # fmt 10's consteval format checker is rejected by Apple Clang 21 and later.
  # Runtime formatting remains unchanged; disable only the incompatible check.
  cmake "$REPO_ROOT_DIR" -G Ninja -DCMAKE_TOOLCHAIN_FILE="$REPO_ROOT_DIR/Externals/ios-cmake/ios.toolchain.cmake" -DPLATFORM=$PLATFORM -DDEPLOYMENT_TARGET=$PLATFORM_DEPLOYMENT_TARGET -DENABLE_VISIBILITY=ON -DENABLE_BITCODE=OFF -DENABLE_ARC=ON -DCMAKE_BUILD_TYPE=$DOL_CORE_BUILD_TARGET -DCMAKE_CXX_FLAGS="-fPIC -DFMT_CONSTEVAL=" -DIOS=ON -DENABLE_ANALYTICS=NO -DUSE_SYSTEM_LIBS=OFF -DENABLE_TESTS=OFF -DCMAKE_POLICY_VERSION_MINIMUM=3.5
fi

ninja
