#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Feb 23, 2018
# ==================================================================================================
export PYTHON_FOR_BUILD="$(which python2)"
export ARCHS=("x86 x86_64 arm arm64")
export NDK="$HOME/Android/Sdk/ndk-bundle"

# Change insoname
sed -ie 's!INSTSONAME="$LDLIBRARY".$SOVERSION!!g' configure

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
    EXTLIBDIR="lib"
    EXTBUILDDIR="linux2-$ARCH"
    if [ "$ARCH" == "arm" ]; then
        export TARGET_HOST="arm-linux-androideabi"
        export TARGET_ABI="armeabi-v7a"
    elif [ "$ARCH" == "arm64" ]; then
        export TARGET_HOST="aarch64-linux-android"
        export TARGET_ABI="arm64-v8a"
        EXTBUILDDIR="linux2-aarch64"
    elif [ "$ARCH" == "x86" ]; then
        export TARGET_HOST="i686-linux-android"
        export TARGET_ABI="x86"
        EXTBUILDDIR="linux2-i686"
    elif [ "$ARCH" == "x86_64" ]; then
        export TARGET_HOST="x86_64-linux-android"
        export TARGET_ABI="x86_64"
        EXTLIBDIR="lib64"
    fi

    export APP_ROOT="$PREFIX/android/$ARCH"
    export PATH="$PATH:$ANDROID_TOOLCHAIN/bin"
    export AR="$TARGET_HOST-ar"
    export AS="$TARGET_HOST-clang"
    export CC="$TARGET_HOST-clang"
    export CXX="$TARGET_HOST-clang++"
    export LD="$TARGET_HOST-ld"
    export RANLIB="$TARGET_HOST-ranlib"

    export LDSHARED="$CC -shared"
    #export LIBFFI_INCLUDEDIR="$APP_ROOT/include"

    export CROSS_COMPILE="$ARCH"
    export CROSS_COMPILE_TARGET='yes'

    export CFLAGS="-O3 -I$APP_ROOT/include"
    export LDFLAGS="-L$APP_ROOT/lib -L$ANDROID_TOOLCHAIN/sysroot/usr/$EXTLIBDIR" # -lffi -lssl -lcrypto"

    # Flags for building extensions these are patched in
    #export ANDROID_LDFLAGS="$LDFLAGS -L$SRC_DIR -lpython2.7"
    #export ANDROID_LDSHARED="$CC -shared $LDFLAGS"
    #export ANDROID_CFLAGS="$CFLAGS"

    # The magic cross compile flag (tells it to not try to load them after building)
    export _PYTHON_HOST_PLATFORM="$TARGET_HOST"

    # Copy modules and update SSL path
    # If you want to make it smaller remove modules from Setup.local
    cp $RECIPE_DIR/Setup.local $SRC_DIR/Modules/
    sed -ie s!SSL=/usr/local/ssl!SSL=$APP_ROOT/$SDK/include/!g $SRC_DIR/Modules/Setup.local

    # Install our own setup
    #cp -f $RECIPE_DIR/setup.py $SRC_DIR/

    export

    ./configure ac_cv_file__dev_ptmx=no \
                ac_cv_file__dev_ptc=no \
                ac_cv_have_long_long_format=yes \
                --host=$TARGET_HOST \
                --build=$BUILD \
                --with-threads \
                --with-system-ffi \
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

    # Build libpython
    make -j$CPU_COUNT libpython2.7.so

    # Now build the extensions and be sure to explicitly link python
    # The new setup.py build has all kinds of errors so use the old school way
    # To anyone that wants to try with setup.py have fun :)
    make -j$CPU_COUNT oldsharedmods LDFLAGS="$LDFLAGS -L. -lpython2.7"
    make -C $SRC_DIR install prefix=$SRC_DIR/dist/$ARCH

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
    #cd build/lib.$EXTBUILDDIR-2.7; rename 's/^/lib./' *.so; cd $SRC_DIR
    #cp -RL build/lib.$EXTBUILDDIR-2.7/*.so $PREFIX/android/$ARCH/lib/
    cd Modules; rename 's/^/lib./' *.so; rename 's/module//' *.so; cd ..
    find Modules -type f -name "*.so" -exec cp {} "$PREFIX/android/$ARCH/lib/" \;

    # Copy python
    cp -RL dist/$ARCH/lib/libpython2.7.so $PREFIX/android/$ARCH/lib/
    cp -RL dist/$ARCH/include $PREFIX/android/$ARCH
    cp -RL dist/$ARCH/lib/python2.7/* $PREFIX/android/$ARCH/python

    # Include c++_shared.so
    cp -RL $ANDROID_TOOLCHAIN/$TARGET_HOST/$EXTLIBDIR/libc++_shared.so $PREFIX/android/$ARCH/lib

    # Strip libs of debug symbol
    chmod 775 $PREFIX/android/$ARCH/lib/libpython2.7.so
    #find $PREFIX/android/$ARCH/lib -name "*.so" \
    #     -exec ${STRIP} --strip-unneeded {} \;
    #exit 1
done
