#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Feb 28, 2018
# ==================================================================================================
source $PREFIX/android/activate-ndk.sh

for ARCH in $ARCHS
do

    # Setup compiler for arch and target_api
    activate-ndk-clang $ARCH

    ./configure --host=$TARGET_HOST --enable-shared --prefix=$SRC_DIR/dist/$ARCH

    # Clean
    make clean

    # Build
    make -j$CPU_COUNT
    make install

    # Copy to install dir
    mkdir -p $PREFIX/android/$ARCH/lib
    cp -RL dist/$ARCH/lib/libgeos_c.so $PREFIX/android/$ARCH/lib
    cp -RL dist/$ARCH/include $PREFIX/android/$ARCH/
    validate-lib-arch $PREFIX/android/$ARCH/lib/*.so
done


