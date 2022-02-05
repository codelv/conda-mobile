#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Feb 23, 2018
# ==================================================================================================
source $PREFIX/android/activate-ndk.sh

# Remove versions
sed -i.bak 's/SOVERSION ${TURBOJPEG_SO_MAJOR_VERSION} VERSION ${TURBOJPEG_SO_VERSION}/NO_SONAME 1/g' CMakeLists.txt
sed -i.bak 's/VERSION ${SO_MAJOR_VERSION}.${SO_AGE}.${SO_MINOR_VERSION}/NO_SONAME 1/g' sharedlib/CMakeLists.txt

for ARCH in $ARCHS
do
    # Setup compiler for arch and target_api
    activate-ndk-clang $ARCH 32

    export CFLAGS="-O2 -fPIE -w"
    if [ "$ARCH" == "arm" ]; then
        export CFLAGS="$CFLAGS -D__ARM_NEON__ -march=armv7-a -mfloat-abi=softfp -fprefetch-loop-arrays"
    fi

    rm -Rf build || true
    mkdir build
    cd build
        cmake .. -G "Unix Makefiles" \
        -DCMAKE_SYSTEM_NAME=Linux \
        -DCMAKE_FIND_ROOT_PATH="$ANDROID_TOOLCHAIN/sysroot" \
        -DCMAKE_C_COMPILER="$CC" \
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


