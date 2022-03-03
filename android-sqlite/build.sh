#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Feb 23, 2018
# ==================================================================================================
source $BUILD_PREFIX/android/activate-ndk.sh

for ARCH in $ARCHS
do

    # Setup compiler for arch and target_api
    activate-ndk-clang $ARCH
    export STRIP="$TARGET_HOST-strip"
    export CFLAGS="$CFLAGS -Os"

    ./configure --host=$TARGET_HOST --prefix=$SRC_DIR/dist/$ARCH --with-sysroot=$ANDROID_TOOLCHAIN/sysroot
    make clean
    make -j$CPU_COUNT
    make install

    mkdir -p $PREFIX/android/$ARCH/lib
    cp -RL dist/$ARCH/lib/libsqlite3.so $PREFIX/android/$ARCH/lib
    cp -RL dist/$ARCH/include $PREFIX/android/$ARCH/
    validate-lib-arch $PREFIX/android/$ARCH/lib/*.so

done
