#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Mar 20, 2018
# ==================================================================================================
source $BUILD_PREFIX/android/activate-ndk.sh

for ARCH in $ARCHS
do
    activate-ndk-clang $ARCH
    export LDFLAGS="$LDFLAGS -lxml2 -llzma -lz -lm"

    ./autogen.sh
    ./configure --host=$TARGET_HOST --prefix=$SRC_DIR/dist/$ARCH \
                --enable-static=no \
                --without-python \
                --without-crypto \
                --with-libxml-include-prefix=$APP_ROOT/include \
                --with-libxml-libs-prefix=$APP_ROOT/lib

    # Clean
    make clean
    touch doc/xsltproc.1

    # Build
    make -j$CPU_COUNT
    make install

    # Copy to install dir
    mkdir -p $PREFIX/android/$ARCH/lib
    mkdir -p $PREFIX/android/$ARCH/include
    cp -RL dist/$ARCH/lib/lib*.so $PREFIX/android/$ARCH/lib
    cp -RL dist/$ARCH/include/* $PREFIX/android/$ARCH/include
    validate-lib-arch $PREFIX/android/$ARCH/lib/*.so

done


