#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Copyright 2018 by Rodrigo Gomes <rodgomesc@gmail.com>
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Nov 22, 2018
# ==================================================================================================
source $BUILD_PREFIX/android/activate-ndk.sh

for ARCH in $ARCHS
do
    # Setup compiler for arch and target_api
    activate-ndk-clang $ARCH

    if [ "${TARGET_ABI}" = "armeabi" ]; then
        API_LEVEL=19
    fi

    rm -Rf build || true
    mkdir build
    cd build
    cmake .. -G "Unix Makefiles" -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
        -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" \
        -DANDROID_ARM_NEON=ON \
        -DANDROID_NDK="${ANDROID_NDK_HOME}" \
        -DANDROID_NATIVE_API_LEVEL=${API_LEVEL} \
        -DANDROID_ABI="${ANDROID_ABI}" \
        -DCMAKE_FIND_ROOT_PATH="$ANDROID_TOOLCHAIN/sysroot" \
        -DCMAKE_C_COMPILER=$CC \
        -DCMAKE_SYSTEM_PROCESSOR=$ARCH \
        -DWITH_CUDA=OFF \
        -DBUILD_ANDROID_EXAMPLES=OFF \
        -DBUILD_DOCS=OFF \
        -DBUILD_PERF_TESTS=OFF \
        -DBUILD_TESTS=OFF \
        -DBUILD_PNG=OFF \
        -DBUILD_TIFF=OFF \
        -DBUILD_TBB=OFF \
        -DBUILD_JPEG=OFF \
        -DBUILD_JASPER=OFF \
        -DBUILD_ANDROID_PROJECTS=OFF \
        -DBUILD_ANDROID_STL="libc++_shared" \
        -DCMAKE_INSTALL_PREFIX=$SRC_DIR/dist/$ARCH

        make -j$CPU_COUNT
        #make install
        cd $SRC_DIR

    # Copy to install dir
    mkdir -p $PREFIX/android/$ARCH/lib
    mkdir -p $PREFIX/android/$ARCH/include
    cp -RL dist/$ARCH/lib/libopencv.so $PREFIX/android/$ARCH/lib
    cp -RL dist/$ARCH/include/* $PREFIX/android/$ARCH/include
    validate-lib-arch $PREFIX/android/$ARCH/lib/*.so

done


