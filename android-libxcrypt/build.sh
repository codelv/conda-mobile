#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2022, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Mar 1, 2022
# ==================================================================================================
source $BUILD_PREFIX/android/activate-ndk.sh

for ARCH in $ARCHS
do
    activate-ndk-clang $ARCH
    export CFLAGS="-I$APP_ROOT/include -Wno-language-extension-token"
    export LDFLAGS="-L$APP_ROOT/lib"

    ./configure --host=$TARGET_HOST --prefix=$SRC_DIR/dist/$ARCH \
        --with-sysroot=$ANDROID_TOOLCHAIN/sysroot \
        --disable-obsolete-api \
        --enable-hashes=all

    # Cleanup old build
    make clean
    # Build
    make -j$CPU_COUNT
    make install

    # Copy to install dir
    mkdir -p $PREFIX/android/$ARCH/lib
    mkdir -p $PREFIX/android/$ARCH/include
    cp -RL dist/$ARCH/lib/libcrypt.so $PREFIX/android/$ARCH/lib
    cp -RL dist/$ARCH/include/* $PREFIX/android/$ARCH/include
    validate-lib-arch $PREFIX/android/$ARCH/lib/*.so
done


