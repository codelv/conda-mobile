#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Apr 19, 2018
# ==================================================================================================
export ARCHS=("x86_64 x86 arm arm64")
export NDK="$HOME/Android/Sdk/ndk-bundle"


for ARCH in $ARCHS
do

    CONFIGURE_FLAGS=""
    if [ "$ARCH" == "arm" ]; then
        export TARGET_HOST="arm-linux-androideabi"
        export TARGET_ABI="armeabi-v7a"
        CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-arm-neon"
    elif [ "$ARCH" == "arm64" ]; then
        export TARGET_HOST="aarch64-linux-android"
        export TARGET_ABI="arm64-v8a"
        CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-arm-neon"
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
    #export AS="$TARGET_HOST-clang"
    export CC="$TARGET_HOST-clang"
    export CXX="$TARGET_HOST-clang++"
    export LD="$TARGET_HOST-ld"


    rm -Rf build || true
    mkdir build
    cd build
        cmake .. -G "Unix Makefiles" -DCMAKE_SYSTEM_NAME=Linux \
                              -DCMAKE_FIND_ROOT_PATH="$ANDROID_TOOLCHAIN/sysroot" \
                              -DCMAKE_C_COMPILER="$TARGET_HOST-clang" \
                              -DCMAKE_ASM_COMPILER="$TARGET_HOST-clang" \
                              -DCMAKE_SYSTEM_PROCESSOR=$ARCH \
                              -DENABLE_STATIC=0 \
                              -DCMAKE_INSTALL_PREFIX=$SRC_DIR/dist/$ARCH

        make -j$CPU_COUNT
        make install
    cd $SRC_DIR

    # Copy to install dir
    mkdir -p $PREFIX/android/$ARCH/lib
    mkdir -p $PREFIX/android/$ARCH/include
    cp -RL dist/$ARCH/lib/libpng.so $PREFIX/android/$ARCH/lib
    cp -RL dist/$ARCH/include/* $PREFIX/android/$ARCH/include

done


