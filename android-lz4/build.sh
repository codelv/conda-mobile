#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Feb 23, 2018
# ==================================================================================================
source $PREFIX/android/activate-ndk.sh

for ARCH in $ARCHS
do

    # Setup compiler for arch and target_api
    activate-ndk-clang $ARCH

    # Clean
    make clean

    cd lib
    # Build
    make liblz4 -j$CPU_COUNT

    cd $SRC_DIR

    # Copy to install dir
    mkdir -p $PREFIX/android/$ARCH/lib
    mkdir -p $PREFIX/android/$ARCH/include
    validate-lib-arch lib/liblz4.so
    cp -RL lib/liblz4.so $PREFIX/android/$ARCH/lib
    cp -RL lib/*.h $PREFIX/android/$ARCH/include
    rm $PREFIX/android/$ARCH/include/*_static.h

done


