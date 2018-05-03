#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Feb 23, 2018
# ==================================================================================================
export ARCHS=("x86_64 x86 arm arm64")
export NDK="$HOME/Android/Sdk/ndk-bundle"

# Remove versions
sed -i.bak 's/SOVERSION ${TURBOJPEG_SO_MAJOR_VERSION} VERSION ${TURBOJPEG_SO_VERSION}/NO_SONAME 1/g' CMakeLists.txt
sed -i.bak 's/VERSION ${SO_MAJOR_VERSION}.${SO_AGE}.${SO_MINOR_VERSION}/NO_SONAME 1/g' sharedlib/CMakeLists.txt

for ARCH in $ARCHS
do
    export CFLAGS="-O2 -fPIE -w"

    if [ "$ARCH" == "arm" ]; then
        export TARGET_HOST="arm-linux-androideabi"
        export TARGET_ABI="armeabi-v7a"
        export CFLAGS="$CFLAGS -D__ARM_NEON__ -march=armv7-a -mfloat-abi=softfp -fprefetch-loop-arrays"
    elif [ "$ARCH" == "arm64" ]; then
        export TARGET_HOST="aarch64-linux-android"
        export TARGET_ABI="arm64-v8a"
    elif [ "$ARCH" == "x86" ]; then
        export TARGET_HOST="i686-linux-android"
        export TARGET_ABI="x86"
    elif [ "$ARCH" == "x86_64" ]; then
        export TARGET_HOST="x86_64-linux-android"
        export TARGET_ABI="x86_64"
    fi

    export ANDROID_TOOLCHAIN="$NDK/standalone/$ARCH"
    export APP_ROOT="$PREFIX/android/$ARCH"
    export PATH="$PATH:$ANDROID_TOOLCHAIN/bin"
    export AR="$TARGET_HOST-ar"
    export AS="$TARGET_HOST-clang"
    export CC="$TARGET_HOST-clang"
    export CXX="$TARGET_HOST-clang++"
    export LD="$TARGET_HOST-ld"

    rm -Rf build || true
    mkdir build
    cd build
        cmake .. -G "Unix Makefiles" -DCMAKE_SYSTEM_NAME=Linux \
                              -DCMAKE_FIND_ROOT_PATH="$ANDROID_TOOLCHAIN/sysroot" \
                              -DCMAKE_C_COMPILER="$TARGET_HOST-clang" \
                              -DCMAKE_SYSTEM_PROCESSOR=$ARCH \
                              -DENABLE_STATIC=0 \
                              -DCMAKE_INSTALL_PREFIX=$SRC_DIR/dist/$ARCH

        make -j$CPU_COUNT
        make install
    cd $SRC_DIR

    # Copy to install dir
    mkdir -p $PREFIX/android/$ARCH/lib
    mkdir -p $PREFIX/android/$ARCH/include
    cp -RL dist/$ARCH/lib/libjpeg.so $PREFIX/android/$ARCH/lib
    cp -RL dist/$ARCH/lib/libturbojpeg.so $PREFIX/android/$ARCH/lib
    cp -RL dist/$ARCH/include/* $PREFIX/android/$ARCH/include

done


