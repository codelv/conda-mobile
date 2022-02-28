#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2022, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Feb 4, 2022
# ==================================================================================================
# This file is installed by the android-ndk package
# To use it include the following in your build script:
#
# source $PREFIX/android/activate-ndk.sh
# for ARCH in $ARCHS
# do
#    # Setup compiler for arch
#    activate-ndk-clang $ARCH
#    # your script...
# done
#
export NDK_VERSION="23.1.7779620"
export ANDROID_NDK_HOME="$HOME/Android/Sdk/ndk/$NDK_VERSION"
export ANDROID_TOOLCHAIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64"
export ARCHS=("x86_64 x86 arm arm64")
export PATH="$ANDROID_TOOLCHAIN/bin:$PATH"


function activate-ndk-clang() {
    export ARCH="$1"
    export TARGET_API="31"

    if [ "$ARCH" == "arm" ]; then
        export TARGET_HOST="armv7a-linux-androideabi"
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


    # Compiler setup
    export APP_ROOT="$PREFIX/android/$ARCH"
    export CC="$TARGET_HOST$TARGET_API-clang"
    export CXX="$TARGET_HOST$TARGET_API-clang++"
    export AR="llvm-ar"
    export LD="llvm-ld"
    export READELF="llvm-readelf"

    # NDK paths
    export NDK_INC_DIR="$ANDROID_TOOLCHAIN/sysroot/usr/include"
    export NDK_LIB_DIR="$ANDROID_TOOLCHAIN/sysroot/usr/lib/$TARGET_HOST/$TARGET_API"
    if [ "$ARCH" == "arm" ]; then
        export NDK_LIB_DIR="$ANDROID_TOOLCHAIN/sysroot/usr/lib/arm-linux-androideabi/$TARGET_API"
    fi

}
