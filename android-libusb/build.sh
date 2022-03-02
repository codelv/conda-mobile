#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Feb 23, 2018
# ==================================================================================================
source $BUILD_PREFIX/android/activate-ndk.sh

cd android/jni
$ANDROID_NDK_HOME/ndk-build
cd ../../

for ARCH in $ARCHS
do
    # Use activate to set target abi and build output dirs
    activate-ndk-clang $ARCH
    cp -RL android/libs/$TARGET_ABI/libusb1.0.so $PREFIX/android/$ARCH/lib
    cp -RL libusb/libusb.h $PREFIX/android/$ARCH/include
    validate-lib-arch $PREFIX/android/$ARCH/lib/*.so
done
