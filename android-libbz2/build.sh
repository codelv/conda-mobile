#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Apr 19, 2018
# ==================================================================================================
source $PREFIX/android/activate-ndk.sh

# Use our modified version of the Makefile-libbz2_so to Build the shared lib without a version
cp -f $RECIPE_DIR/Makefile Makefile

for ARCH in $ARCHS
do

    # Setup compiler for arch and target_api
    activate-ndk-clang $ARCH

    # Clean
    make clean

    # Build
    make -j$CPU_COUNT

    # Copy to install dir
    mkdir -p $PREFIX/android/$ARCH/lib
    mkdir -p $PREFIX/android/$ARCH/include
    cp -RL libbz2.so $PREFIX/android/$ARCH/lib
    cp -RL *.h $PREFIX/android/$ARCH/include
    validate-lib-arch $PREFIX/android/$ARCH/lib/*.so
done


