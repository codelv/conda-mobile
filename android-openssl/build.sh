#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Feb 23, 2018
# ==================================================================================================
export ARCHS=("arm arm64 x86_64 x86")
export NDK="$HOME/Android/Sdk/ndk-bundle"

for ARCH in $ARCHS
do
    CCOMPILER="clang"
    if [ "$ARCH" == "arm" ]; then
        export TARGET_HOST="arm-linux-androideabi"
        export TARGET="android-armeabi"
        CCOMPILER="gcc" # android-armv7 doesn't seem to work with clang
    elif [ "$ARCH" == "arm64" ]; then
        export TARGET_HOST="aarch64-linux-android"
        export TARGET="android64-aarch64"
    elif [ "$ARCH" == "x86" ]; then
        export TARGET_HOST="i686-linux-android"
        export TARGET="android-x86"
        CCOMPILER="gcc" # android-x86 doesn't seem to work with clang
    elif [ "$ARCH" == "x86_64" ]; then
        export TARGET_HOST="x86_64-linux-android"
        export TARGET="android64"
    fi

    export ANDROID_TOOLCHAIN="$NDK/standalone/$ARCH"
    export APP_ROOT="$PREFIX/android/$ARCH"
    export PATH="$PATH:$ANDROID_TOOLCHAIN/bin"
    export AR="$TARGET_HOST-ar"
    export CC="$TARGET_HOST-$CCOMPILER"
    export LD="$TARGET_HOST-ld"

    # Configure for iphoneos
    perl Configure $TARGET -shared

    # Clean
    make clean

    # Remove version otherwise it tries to link a specific version
    sed -ie 's!SHLIB_EXT=.so.$(SHLIB_MAJOR).$(SHLIB_MINOR)!SHLIB_EXT=.so!g' Makefile
    sed -ie 's!-soname=$$SHLIB$$SHLIB_SOVER$$SHLIB_SUFFIX!-soname=$$SHLIB!g' Makefile.shared

    # Remove -mandroid because NDK r19 sucks and removed gcc
    # of course "it's not due to licensing", right.... nice one!
    sed -ie 's!-mandroid!!g' Makefile

    # Build
    make -j$CPU_COUNT build_libs LIBDIR=. SHLIB_EXT=.so

    # Copy to install dir
    mkdir -p $PREFIX/android/$ARCH/lib
    cp -RL lib*.so $PREFIX/android/$ARCH/lib
    cp -RL include $PREFIX/android/$ARCH/

done
