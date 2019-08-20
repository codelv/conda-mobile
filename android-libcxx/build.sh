#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Feb 23, 2018
# ==================================================================================================
export ARCHS=("x86_64 x86 arm arm64")
export NDK="$HOME/Android/Sdk/ndk-bundle"

for ARCH in $ARCHS
do
    EXTLIBDIR="lib"
    if [ "$ARCH" == "arm" ]; then
        export TARGET_HOST="arm-linux-androideabi"
    elif [ "$ARCH" == "arm64" ]; then
        export TARGET_HOST="aarch64-linux-android"
    elif [ "$ARCH" == "x86" ]; then
        export TARGET_HOST="i686-linux-android"
    elif [ "$ARCH" == "x86_64" ]; then
        export TARGET_HOST="x86_64-linux-android"
        EXTLIBDIR="lib64"
    fi

    export ANDROID_TOOLCHAIN="$NDK/standalone/$ARCH"

    # Include c++_shared.so
    mkdir -p $PREFIX/android/$ARCH/lib
    cp -RL $ANDROID_TOOLCHAIN/sysroot/usr/lib/$TARGET_HOST/libc++_shared.so $PREFIX/android/$ARCH/lib
done
