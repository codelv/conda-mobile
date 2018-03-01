#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
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
        # iPhone builds cannot use the private API _NSGetEnviron
        sed -ie "s!environ = *_NSGetEnviron();!environ = NULL;!g" Modules/posixmodule.c

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
    export LDFLAGS="-arch $ARCH --sysroot $SYSROOT $VERSION_MIN -L$APP_ROOT/lib" # -lsqlite3 -lffi -lssl -lcrypto

    # The magic cross compile flag (tells it to not try to load them after building)
    export CROSS_COMPILE_TARGET='yes'
    export _PYTHON_HOST_PLATFORM="$TARGET_HOST"

    ./configure ac_cv_file__dev_ptmx=no \
                ac_cv_file__dev_ptc=no \
                --host=$TARGET_HOST \
                --build=$BUILD \
                --with-threads \
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
    make -j$CPU_COUNT libpython2.7.dylib

    export LDFLAGS="$LDFLAGS -L. -lpython2.7"
    make -j$CPU_COUNT oldsharedmods SO=.dylib
    make -C $SRC_DIR install prefix=$SRC_DIR/dist/$ARCH

    # Rename to dylib, remove module, and move to libs
    cd dist/$ARCH/lib/python2.7/lib-dynload;
        rename 's/^/lib./' *.so
        rename 's/\.so/.dylib/' *.so
        rename 's/module//' *.dylib
        cp *.dylib $SRC_DIR/dist/$ARCH/lib
    cd $SRC_DIR

    # Remove unused stuff
    rm -Rf dist/$ARCH/lib/python2.7/test
    rm -Rf dist/$ARCH/lib/python2.7/*/test/
    rm -Rf dist/$ARCH/lib/python2.7/*/tests/
    rm -Rf dist/$ARCH/lib/python2.7/plat-*
    rm -Rf dist/$ARCH/lib/python2.7/lib-*
    rm -Rf dist/$ARCH/lib/python2.7/config
done


# Create outputs
mkdir $PREFIX/iphoneos/python
mkdir $PREFIX/iphonesimulator/python

# Make a single lib with both for the iphone
cd dist/armv7/lib/
find *.dylib -exec lipo -create $SRC_DIR/dist/armv7/lib/{} \
                                $SRC_DIR/dist/arm64/lib/{} \
                                -o $PREFIX/iphoneos/lib/{} \;
cd $SRC_DIR

# Copy headers and stdlib
cp -RL dist/armv7/include $PREFIX/iphoneos/
cp -RL dist/armv7/lib/python2.7/* $PREFIX/iphoneos/python


# Make a single lib with both for the iphonesimulator
cd dist/x86_64/lib/
find *.dylib -exec lipo -create $SRC_DIR/dist/x86_64/lib/{} \
                                $SRC_DIR/dist/i386/lib/{} \
                                -o $PREFIX/iphonesimulator/lib/{} \;
cd $SRC_DIR


# Copy headers and stdlib
cp -RL dist/x86_64/include $PREFIX/iphonesimulator/
cp -RL dist/x86_64/lib/python2.7/* $PREFIX/iphonesimulator/python


# Use this to debug the outputs
#exit 1