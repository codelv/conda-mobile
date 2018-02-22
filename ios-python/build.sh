#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the MIT License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Feb 10, 2018
# ==================================================================================================

export PYTHON_FOR_BUILD="$(which python2)"
export VERSION_MIN="-miphoneos-version-min=8.0.0"
export ARCHS=("i386 x86_64 armv7 arm64")

# Patch
patch -t -d $SRC_DIR -p1 -i $RECIPE_DIR/patches/xcompile.patch

# Add MODULE_NAME
patch -t -d $SRC_DIR -p1 -i $RECIPE_DIR/patches/sqlite.patch

# Patch the makefile to use the install_name "@rpath/"
patch -t -d $SRC_DIR -p1 -i $RECIPE_DIR/patches/rpath.patch

# Remove crt_extensions and use of private API
patch -t -d $SRC_DIR -p1 -i $RECIPE_DIR/patches/posixmodule.patch

for ARCH in $ARCHS
do

    if [ "$ARCH" == "armv7" ]; then
        export SDK="iphoneos"
        export TARGET_HOST="armv7-apple-darwin"
    elif [ "$ARCH" == "arm64" ]; then
        export SDK="iphoneos"
        export TARGET_HOST="aarch64-apple-darwin"
    else
        export SDK="iphonesimulator"
        export TARGET_HOST="$ARCH-apple-darwin"
    fi

    export APP_ROOT="$PREFIX/$SDK"
    export SYSROOT="$(xcrun --sdk $SDK --show-sdk-path)"

    # Copy modules and update SSL path
    # If you want to make it smaller remove modules from Setup.local
    cp $RECIPE_DIR/Setup.local $SRC_DIR/Modules/
    sed -i.bak s!SSL=/usr/local/ssl!SSL=$APP_ROOT/$SDK/include/!g $SRC_DIR/Modules/Setup.local

    #export USE_CCACHE="1"
    #export CCACHE="$(which ccache)"
    export CC="$(xcrun -find -sdk $SDK gcc)"
    export CFLAGS="-arch $ARCH -pipe --sysroot $SYSROOT -isysroot $SYSROOT -O3 $VERSION_MIN -I$APP_ROOT/include"
    export AR="$(xcrun -find -sdk $SDK ar)"
    export CXX="$(xcrun -find -sdk $SDK g++)"
    export LD="$(xcrun -find -sdk $SDK ld)"
    export LDFLAGS="-arch $ARCH --sysroot $SYSROOT $VERSION_MIN -L$APP_ROOT/lib -lsqlite3 -lffi -lssl -lcrypto"

    # The magic cross compile flag (tells it to not try to load them after building)
    export _PYTHON_HOST_PLATFORM="$TARGET_HOST"

    ./configure CC="$CC" \
                LD="$LD" \
                CLFAGS="$CFLAGS" \
                LDFLAGS="$LDFLAGS" \
                ac_cv_file__dev_ptmx=no \
                ac_cv_file__dev_ptc=no \
                --host=$TARGET_HOST \
                --build=$BUILD \
                --without-pymalloc \
                --disable-toolbox-glue \
                --enable-ipv6 \
                --enable-shared \
                --with-system-ffi \
                --without-doc-strings
                #--enable-optimizations

    make clean

    # Use ARC4RANDOM or we get an error building expat
    sed -ie "s!HAVE_GETENTROPY!HAVE_ARC4RANDOM_BUF!g" pyconfig.h

    # The with-system-ffi flag is ignored for some reason
    sed -ie "s!LIBFFI_INCLUDEDIR=	!LIBFFI_INCLUDEDIR=$APP_ROOT/include/!g" Makefile

    # Build and install
    make -j$CPU_COUNT CROSS_COMPILE_TARGET=yes
    make -C $SRC_DIR install CROSS_COMPILE_TARGET=yes \
                    prefix=$SRC_DIR/dist/$ARCH


done


# Create outputs
mkdir $PREFIX/iphoneos/python
mkdir $PREFIX/iphonesimulator/python

# Make a single lib with both for the iphone
lipo -create dist/armv7/lib/libpython2.7.dylib \
             dist/arm64/lib/libpython2.7.dylib \
             -o $PREFIX/iphoneos/lib/libpython2.7.dylib

# Copy headers and stdlib
cp -RL dist/armv7/include $PREFIX/iphoneos/
cp -RL dist/armv7/lib/python2.7/* $PREFIX/iphoneos/python

# Make a single lib with both for the iphone
lipo -create dist/i386/lib/libpython2.7.dylib \
             dist/x86_64/lib/libpython2.7.dylib \
             -o $PREFIX/iphonesimulator/lib/libpython2.7.dylib

# Copy headers and stdlib
cp -RL dist/x86_64/include $PREFIX/iphoneos/
cp -RL dist/x86_64/lib/python2.7/* $PREFIX/iphonesimulator/python


# Use this to debug the outputs
#exit 1