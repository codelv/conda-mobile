#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the MIT License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Feb 10, 2018
# ==================================================================================================

export DEVELOPER="$(xcode-select -print-path)"
export VERSION_MIN="-miphoneos-version-min=8.0.0"
export BUILD_TOOLS="${DEVELOPER}"
export ARCHS=("i386 x86_64 armv7 arm64")


for ARCH in $ARCHS
do
    if [ "$ARCH" == "i386" ] || [ "$ARCH" == "x86_64" ]; then
        export SDK="iphonesimulator"
        export PLATFORM="iPhoneSimulator"
        if [ "$ARCH" == "x86_64" ]; then
            export TARGET="darwin64-x86_64-cc"
        else
            export TARGET="darwin-i386-cc"
        fi
    else
        export SDK="iphoneos"
        export PLATFORM="iPhoneOS"
        export TARGET="iphoneos-cross"
        sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
    fi

    export SYSROOT="$(xcrun --sdk $SDK --show-sdk-path)"
    export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
    export CROSS_SDK="$PLATFORM$(xcrun --sdk $SDK --show-sdk-platform-version).sdk"
    export TOOLS="${DEVELOPER}"

    # Note the -miphoneos-version-min flag is required!
    export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH} $VERSION_MIN"

    # Configure for iphoneos
    perl Configure $TARGET -shared --prefix=@rpath
    # TODO: Use --cross-compile-prefix=$BUILD_TOOLS

    # Clean
    make clean

    FIND='SHLIB_EXT=.\$(SHLIB_MAJOR).\$(SHLIB_MINOR).dylib'
    sed -ie s!$FIND!SHLIB_EXT=.dylib!g Makefile
    #sed -ie "s!LIBRPATH=\'\$(INSTALLTOP)/\$(LIBDIR)!LIBRPATH=@rpath!g" Makefile


    # Build
    make -j$CPU_COUNT build_libs LIBDIR=.

    # Copy to install dir
    mkdir $ARCH
    cp -RL lib*.dylib $ARCH/

done

mkdir $PREFIX/iphoneos
mkdir $PREFIX/iphoneos/lib
mkdir $PREFIX/iphonesimulator
mkdir $PREFIX/iphonesimulator/lib

# Merge iphoneos libs
lipo -create armv7/libssl.dylib \
             arm64/libssl.dylib \
             -output $PREFIX/iphoneos/lib/libssl.dylib

lipo -create armv7/libcrypto.dylib \
             arm64/libcrypto.dylib \
             -output $PREFIX/iphoneos/lib/libcrypto.dylib
cp -RL include $PREFIX/iphoneos

# Merge simulator libs
lipo -create i386/libssl.1.0.0.dylib \
             x86_64/libssl.1.0.0.dylib \
             -output $PREFIX/iphonesimulator/lib/libssl.dylib

lipo -create i386/libcrypto.1.0.0.dylib \
             x86_64/libcrypto.1.0.0.dylib \
             -output $PREFIX/iphonesimulator/lib/libcrypto.dylib

cp -RL include $PREFIX/iphonesimulator

