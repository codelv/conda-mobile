#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the MIT License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Feb 23, 2018
# ==================================================================================================
export PYTHON_FOR_BUILD="$(which python2)"
export ARCHS=("x86_64 x86 arm arm64")
export NDK="$HOME/Android/Sdk/ndk-bundle"

# Patch
patch -t -d $SRC_DIR -p1 -i $RECIPE_DIR/patches/xcompile.patch
patch -t -d $SRC_DIR -p1 -i $RECIPE_DIR/patches/setup.patch
patch -t -d $SRC_DIR -p1 -i $RECIPE_DIR/patches/sqlite.patch

# Disable LFS
sed -ie "s!use_lfs=yes!use_lfs=no!g" configure

for ARCH in $ARCHS
do
# This expects the toolchain to be built at $NDK/standalone/$ARCH
#   python $NDK/build/tools/make_standalone_toolchain.py \
#                                            --arch $ARCH \
#                                            --api 26 \
#                                            --stl=libc++ \
#                                            --install-dir=$NDK/standalone/$ARCH
    export ANDROID_TOOLCHAIN="$NDK/standalone/$ARCH"
    LIBDIR="lib"
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
        LIBDIR="lib64"
    fi

    export APP_ROOT="$PREFIX/android/$ARCH"
    export PATH="$PATH:$ANDROID_TOOLCHAIN/bin"
    export AR="$TARGET_HOST-ar"
    export RC="$TARGET_HOST-rc"
    export CC="$TARGET_HOST-clang"
    export CXX="$TARGET_HOST-clang++"
    export LD="$TARGET_HOST-ld"
    export RANLIB="$TARGET_HOST-ranlib"
    export STRIP="$TARGET_HOST-strip"

    export CFLAGS="-O3 -I$APP_ROOT/include"
    export LDFLAGS="-L$APP_ROOT/lib"

    # The magic cross compile flag (tells it to not try to load them after building)
    export _PYTHON_HOST_PLATFORM="$TARGET_HOST"

    # Copy modules and update SSL path
    # If you want to make it smaller remove modules from Setup.local
    cp $RECIPE_DIR/Setup.local $SRC_DIR/Modules/
    sed -ie s!SSL=/usr/local/ssl!SSL=$APP_ROOT/$SDK/include/!g $SRC_DIR/Modules/Setup.local

    ./configure ac_cv_file__dev_ptmx=no \
                ac_cv_file__dev_ptc=no \
                ac_cv_have_long_long_format=yes \
                --host=$TARGET_HOST \
                --build=$BUILD \
                --without-pymalloc \
                --disable-toolbox-glue \
                --enable-ipv6 \
                --enable-shared \
                --with-system-ffi \
                --without-doc-strings

    make clean

    # Disable langinfo android has it but not full support (missing nl_langinfo)
    sed -ie 's!#define HAVE_LANGINFO_H 1!/* #undef HAVE_LANGINFO_H */!g' pyconfig.h

    # termios
    sed -ie 's!#define HAVE_CTERMID 1!/* #undef HAVE_CTERMID */!g' pyconfig.h
    sed -ie 's!#define HAVE_OPENPTY 1!/* #undef HAVE_OPENPTY */!g' pyconfig.h
    sed -ie 's!#define HAVE_FORKPTY 1!/* #undef HAVE_FORKPTY */!g' pyconfig.h

    # pwdmodule
    sed -ie 's!#define HAVE_GETPWENT 1!/* #undef HAVE_GETPWENT */!g' pyconfig.h


    # Build and install
    make -j$CPU_COUNT CROSS_COMPILE_TARGET=yes
    make -C $SRC_DIR install CROSS_COMPILE_TARGET=yes \
                    prefix=$SRC_DIR/dist/$ARCH

    # Remove unused stuff
    rm -Rf dist/$ARCH/lib/python2.7/test
    rm -Rf dist/$ARCH/lib/python2.7/*/test/
    rm -Rf dist/$ARCH/lib/python2.7/*/tests/
    rm -Rf dist/$ARCH/lib/python2.7/plat-*
    rm -Rf dist/$ARCH/lib/python2.7/lib-*
    rm -Rf dist/$ARCH/lib/python2.7/config


    mkdir -p $PREFIX/android/$ARCH/lib
    mkdir -p $PREFIX/android/$ARCH/python

    # Prefix with lib., remove module from name, and copy extensions
    cd Modules; rename 's/^/lib./' *.so; rename 's/module//' *.so; cd ..
    find Modules -type f -name "*.so" -exec cp {} "$PREFIX/android/$ARCH/lib/" \;

    # Copy python
    cp -RL dist/$ARCH/lib/libpython2.7.so $PREFIX/android/$ARCH/lib/
    cp -RL dist/$ARCH/include $PREFIX/android/$ARCH
    cp -RL dist/$ARCH/lib/python2.7/* $PREFIX/android/$ARCH/python

    # Include c++_shared.so
    cp -RL $ANDROID_TOOLCHAIN/$TARGET_HOST/$LIBDIR/libc++_shared.so $PREFIX/android/$ARCH/lib

    # Strip libs of debug symbol
    chmod 775 $PREFIX/android/$ARCH/lib/libpython2.7.so
    #find $PREFIX/android/$ARCH/lib -name "*.so" \
    #     -exec ${STRIP} --strip-unneeded {} \;

done
