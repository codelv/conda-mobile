#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Apr 19, 2018
# ==================================================================================================
source $PREFIX/android/activate-ndk.sh

# Patch
sed -i -e 's/find_library(M_LIBRARY m)/set(M_LIBRARY ${M_LIBRARY})/g' CMakeLists.txt
sed -i -e 's/find_package(ZLIB REQUIRED)/set(ZLIB_LIBRARY ${ZLIB_LIBRARY})/g' CMakeLists.txt

for ARCH in $ARCHS
do

    activate-ndk-clang $ARCH
    CONFIGURE_FLAGS=""
    if [ "$ARCH" == "arm" ]; then
        CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-arm-neon"
    elif [ "$ARCH" == "arm64" ]; then
        CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-arm-neon"
    fi

    rm -Rf build || true
    mkdir build
    cd build
        cmake .. -G "Unix Makefiles" \
            -DCMAKE_SYSTEM_NAME=Linux \
            -DCMAKE_FIND_ROOT_PATH="$ANDROID_TOOLCHAIN/sysroot" \
            -DCMAKE_C_COMPILER="$CC" \
            -DCMAKE_ASM_COMPILER="$CC" \
            -DCMAKE_SYSTEM_PROCESSOR=$ARCH \
            -DZLIB_LIBRARY="$NDK_LIB_DIR/libz.so" \
            -DZLIB_INCLUDE_DIR="$ARCH_INC_DIR" \
            -DM_LIBRARY="$NDK_LIB_DIR/libm.so" \
            -DCMAKE_INSTALL_PREFIX=$SRC_DIR/dist/$ARCH

        make -j$CPU_COUNT
        make install
    cd $SRC_DIR

    # Copy to install dir
    mkdir -p $PREFIX/android/$ARCH/lib
    mkdir -p $PREFIX/android/$ARCH/include
    validate-lib-arch dist/$ARCH/lib/libpng.so
    cp -RL dist/$ARCH/lib/libpng.so $PREFIX/android/$ARCH/lib
    cp -RL dist/$ARCH/include/* $PREFIX/android/$ARCH/include

done
