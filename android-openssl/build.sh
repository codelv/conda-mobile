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
    activate-ndk-clang $ARCH 32

    perl Configure "android-$ARCH" -shared -D__ANDROID_API__=$TARGET_API

    # Clean
    make clean

    # Build
    make -j$CPU_COUNT build_libs LIBDIR=. SHLIB_EXT=.so

    # Copy to install dir
    mkdir -p $PREFIX/android/$ARCH/lib
    cp -RL lib*.so $PREFIX/android/$ARCH/lib
    cp -RL include $PREFIX/android/$ARCH/

done
