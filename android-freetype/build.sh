#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Apr 30, 2018
# ==================================================================================================
source $BUILD_PREFIX/android/activate-ndk.sh

for ARCH in $ARCHS
do

    # Setup compiler for arch and target_api
    activate-ndk-clang $ARCH
    export CFLAGS="-I$APP_ROOT/include"
    export LDFLAGS="-L$APP_ROOT/lib"

    ./configure --host=$TARGET_HOST --prefix=$SRC_DIR/dist/$ARCH --enable-static=no --with-png=no

    # Clean
    make clean

    # Build
    make -j$CPU_COUNT
    make install

    # Copy to install dir
    mkdir -p $PREFIX/android/$ARCH/lib
    mkdir -p $PREFIX/android/$ARCH/include
    cp -RL dist/$ARCH/lib/libfreetype.so $PREFIX/android/$ARCH/lib
    cp -RL dist/$ARCH/include/* $PREFIX/android/$ARCH/include
    validate-lib-arch $PREFIX/android/$ARCH/lib/*.so

done


