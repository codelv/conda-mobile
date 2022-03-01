#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Apr 30, 2018
# ==================================================================================================
source $PREFIX/android/activate-ndk.sh


for ARCH in $ARCHS
do

    # Setup compiler for arch and target_api
    activate-ndk-clang $ARCH
    export CFLAGS="-I$APP_ROOT/include"
    export LDFLAGS="-L$APP_ROOT/lib"

    #./autogen.sh
    ./configure --host=$TARGET_HOST --prefix=$SRC_DIR/dist/$ARCH --enable-static=no \
                --without-freetype --without-glib --without-icu

    # Clean
    make clean

    # Build
    make -j$CPU_COUNT
    make install

    validate-lib-arch dist/$ARCH/lib/libharfbuzz.so

    # Copy to install dir
    mkdir -p $PREFIX/android/$ARCH/lib
    mkdir -p $PREFIX/android/$ARCH/include
    cp -RL dist/$ARCH/lib/libharfbuzz.so $PREFIX/android/$ARCH/lib
    cp -RL dist/$ARCH/lib/libharfbuzz-subset.so $PREFIX/android/$ARCH/lib
    cp -RL dist/$ARCH/include/* $PREFIX/android/$ARCH/include

done


