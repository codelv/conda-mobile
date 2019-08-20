#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Copyright 2018 by Rodrigo Gomes <rodgomesc@gmail.com>
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Nov 22, 2018
# ==================================================================================================

# need Android SDK Tools to version 25.2.5
# Details: https://github.com/opencv/opencv/issues/8460
#sudo ln -s /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /usr/lib/x86_64-linux-gnu/libstdc++.so
 
export ARCHS=("arm arm64")
export NDK="$HOME/Android/Sdk/ndk-bundle"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"



for ARCH in $ARCHS
do

    if [ "$ARCH" == "arm" ]; then
        export TARGET_HOST="arm-linux-androideabi"
        export TARGET_ABI="armeabi-v7a"
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
    #export AS="$TARGET_HOST-clang"
    export CC="$TARGET_HOST-clang"
    export CXX="$TARGET_HOST-clang++"
    export LD="$TARGET_HOST-ld"
    
    if [ "${TARGET_ABI}" = "armeabi" ]; then
        API_LEVEL=19
    else
        API_LEVEL=21
    fi

    rm -Rf build || true
    mkdir build
    cd build       
	cmake .. -G "Unix Makefiles" -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
	      -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
              -DANDROID_ARM_NEON=ON \
	      -DANDROID_NDK="${NDK}" \
	      -DANDROID_NATIVE_API_LEVEL=${API_LEVEL} \
	      -DANDROID_ABI="${ANDROID_ABI}" \
              -DCMAKE_FIND_ROOT_PATH="$ANDROID_TOOLCHAIN/sysroot" \
              -DCMAKE_C_COMPILER="$TARGET_HOST-clang" \
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

done


