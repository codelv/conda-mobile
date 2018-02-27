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

    if [ "$ARCH" == "arm" ]; then
        export TARGET_HOST="arm-linux-androideabi"
        export TARGET_ABI="armeabi-v7a"
    elif [ "$ARCH" == "arm64" ]; then
        export TARGET_HOST="aarch64-linux-android"
        export TARGET_ABI="arm64-v8a"
    elif [ "$ARCH" == "x86" ]; then
        export TARGET_HOST="i686-linux-android"
        export TARGET_ABI="x86"
    elif [ "$ARCH" == "x86_64" ]; then
        export TARGET_HOST="x86_64-linux-android"
        export TARGET_ABI="x86_64"
    fi

    export ANDROID_TOOLCHAIN="$NDK/standalone/$ARCH"
    export APP_ROOT="$PREFIX/android/$ARCH"
    export PATH="$PATH:$ANDROID_TOOLCHAIN/bin"
    export AR="$TARGET_HOST-ar"
    export CC="$TARGET_HOST-clang"
    export LD="$TARGET_HOST-ld"
    export STRIP="$TARGET_HOST-strip"
    export CFLAGS="-Os"

    ./configure --host=$TARGET_HOST --prefix=$SRC_DIR/dist/$ARCH
    make clean
    make -j$CPU_COUNT
    make install

    mkdir -p $PREFIX/android/$ARCH/lib
    cp -RL dist/$ARCH/lib/libsqlite3.so $PREFIX/android/$ARCH/lib
    cp -RL dist/$ARCH/include $PREFIX/android/$ARCH/

    # Strip symbols
    #${STRIP} --strip-unneeded $PREFIX/android/$ARCH/lib/libsqlite3.so

done