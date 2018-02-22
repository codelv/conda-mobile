#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the MIT License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Feb 10, 2018
# ==================================================================================================


# Patch
sed -i.bak s/-miphoneos-version-min=5.1.1/-miphoneos-version-min=8.0/g \
    generate-darwin-source-and-headers.py

patch -t -d $SRC_DIR \
      -p1 -i $RECIPE_DIR/fix-win32-unreferenced-symbol.patch

# Copy project
cp -R $RECIPE_DIR/libffi.xcodeproj $SRC_DIR

# Prepare
./autogen.sh

export SDKS="iphoneos iphonesimulator"

for SDK in $SDKS
do
    if [ "$SDK" == "iphoneos" ]; then
        export LOCAL_ARCH="armv7"
    else
        export LOCAL_ARCH="x86_64"
    fi
    export ARCH

    # Build the project
    xcodebuild -sdk $SDK \
               -project libffi.xcodeproj \
               -target libffi-iOS \
               -configuration Release

    mkdir $PREFIX/$SDK
    mkdir $PREFIX/$SDK/lib
    cp -RL build/Release-$SDK/ $PREFIX/$SDK/lib
    cp -RL build_$SDK-$LOCAL_ARCH/include $PREFIX/$SDK

done
