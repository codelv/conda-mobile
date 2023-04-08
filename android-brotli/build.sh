#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2023, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Feb 23, 2018
# ==================================================================================================
source $BUILD_PREFIX/android/activate-ndk.sh

for ARCH in $ARCHS
do
    # Setup compiler for arch and target_api
    activate-ndk-clang $ARCH

    rm -rf build
    mkdir build
    cd build
        cmake ../ -DCMAKE_INSTALL_PREFIX=$SRC_DIR/dist/$ARCH -DBROTLI_DISABLE_TESTS=1
        # Build
        make -j$CPU_COUNT
        make install
    cd ../

    # Copy to install dir
    mkdir -p $PREFIX/android/$ARCH/lib
    mkdir -p $PREFIX/android/$ARCH/include
    cp -RL dist/$ARCH/lib/libbrotlidec.so $PREFIX/android/$ARCH/lib
    cp -RL dist/$ARCH/lib/libbrotlienc.so $PREFIX/android/$ARCH/lib
    cp -RL dist/$ARCH/lib/libbrotlicommon.so $PREFIX/android/$ARCH/lib
    cp -RL dist/$ARCH/include/* $PREFIX/android/$ARCH/include
    validate-lib-arch $PREFIX/android/$ARCH/lib/*.so
done



