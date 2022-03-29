#!/bin/bash

set -e

PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"

REPO_ROOT_DIR="$PROJECT_DIR/../../.."
CMAKE_BUILD_DIR="$REPO_ROOT_DIR/build-$PLATFORM_NAME-$DOL_CORE_BUILD_TARGET"

case $PLATFORM_NAME in
    iphoneos)
        PLATFORM=OS64
        PLATFORM_DEPLOYMENT_TARGET=$IPHONEOS_DEPLOYMENT_TARGET
        ;;
    iphonesimulator)
        PLATFORM=SIMULATOR64
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
    cd "$CMAKE_BUILD_DIR"
    
    cmake "$REPO_ROOT_DIR" -GNinja -DCMAKE_TOOLCHAIN_FILE="$REPO_ROOT_DIR/Externals/ios-cmake/ios.toolchain.cmake" -DPLATFORM=$PLATFORM -DDEPLOYMENT_TARGET=$PLATFORM_DEPLOYMENT_TARGET -DENABLE_VISIBILITY=ON -DENABLE_BITCODE=OFF -DCMAKE_BUILD_TYPE=$DOL_CORE_BUILD_TARGET -DCMAKE_CXX_FLAGS="-fPIC" -DIOS=ON -DENABLE_ANALYTICS=NO
fi

cd $CMAKE_BUILD_DIR

ninja