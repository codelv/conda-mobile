#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Feb 23, 2018
# ==================================================================================================
source $PREFIX/android/activate-ndk.sh

set -e

# Change insoname
sed -i 's!INSTSONAME="$LDLIBRARY".$SOVERSION!INSTSONAME="$LDLIBRARY"!g' configure
sed -i 's!$(VERSION)$(ABIFLAGS)!$(VERSION)!g' configure

# Add patch for parsing conda's python version header
python $RECIPE_DIR/brand_python.py

sed -i 's!self.inc_dirs = (self.compiler.include_dirs +!self.inc_dirs = (self.compiler.include_dirs + [os.environ["APP_ROOT"] + "/include", os.environ["NDK_INC_DIR"]] + !g' $SRC_DIR/setup.py

for ARCH in $ARCHS
do
    # Setup compiler for arch and target_api
    activate-ndk-clang $ARCH 32

    export CFLAGS="-fPIC -I$APP_ROOT/include -I$NDK_INC_DIR"
    export CCSHARED="-fPIC -I$APP_ROOT/include -I$NDK_INC_DIR -DPy_BUILD_CORE"
    export SSL="$APP_ROOT"
    export LDFLAGS="--sysroot=$ANDROID_TOOLCHAIN/sysroot -L$APP_ROOT/lib -L$NDK_LIB_DIR -llog"
    export _PYTHON_HOST_PLATFORM="$TARGET_HOST"


    #cp $RECIPE_DIR/Setup.local $SRC_DIR/Modules/
    #sed -i s!APP_ROOT=/path/to/app/root/!APP_ROOT=$APP_ROOT/!g $SRC_DIR/Modules/Setup.local

    ./configure \
        ac_cv_file__dev_ptmx=yes \
        ac_cv_file__dev_ptc=no \
        ac_cv_have_long_long_format=yes \
        --with-build-python=$PYTHON \
        --with-ensurepip=install \
        --with-openssl=$APP_ROOT \
        --with-lto \
        --host=$TARGET_HOST \
        --build=$ARCH \
        --enable-ipv6 \
        --enable-optimizations \
        --enable-shared

    sed -i 's!$(BLDSHARED) -o!$(BLDSHARED) -Wl,-soname,$(INSTSONAME) -o!g' Makefile

    make clean

    # Change config
    sed -i 's!\/\* #undef HAVE_BROKEN_POSIX_SEMAPHORES \*\/!#define HAVE_BROKEN_POSIX_SEMAPHORES 1!g' pyconfig.h
    sed -i 's!#define HAVE_GETLOADAVG 1!/* #undef HAVE_GETLOADAVG */!g' pyconfig.h
    sed -i 's!#define HAVE_MEMFD_CREATE 1!/* #undef HAVE_MEMFD_CREATE */!g' pyconfig.h


    # Build libpython
    make -j$CPU_COUNT libpython3.so

    # New script now works but skips some modules like ssl, sqlite
    # so stay with the old..
    #make -j$CPU_COUNT oldsharedmods LDFLAGS="$LDFLAGS -L. -lpython3.10 -landroid"
    make -j$CPU_COUNT sharedmods LDFLAGS="$LDFLAGS -L. -lpython3.10 -landroid"
    make -C $SRC_DIR install prefix=$SRC_DIR/dist/$ARCH

    # Remove example/test modules
    rm dist/$ARCH/lib/python3.10/lib-dynload/xxlim*.so
    rm dist/$ARCH/lib/python3.10/lib-dynload/_xx*.so
    rm dist/$ARCH/lib/python3.10/lib-dynload/*test*.so


    mkdir -p $PREFIX/android/$ARCH/lib
    mkdir -p $PREFIX/android/$ARCH/python

    # Prefix with lib., remove cpython-310 from name, remove module from name, and copy extensions
    # If using oldsharedmods this should just be Modules
    export MOD_DIR="dist/$ARCH/lib/python3.10/lib-dynload"
    cd $MOD_DIR; rename 's/^/lib./' *.so; rename 's/.cpython-310//' *.so; rename 's/module//' *.so; cd $SRC_DIR
    find $MOD_DIR -type f -name "*.so" -exec cp {} "$PREFIX/android/$ARCH/lib/" \;

    # Remove unused stuff
    rm -rf dist/$ARCH/lib/python3.10/test
    rm -rf dist/$ARCH/lib/python3.10/*/test/
    rm -rf dist/$ARCH/lib/python3.10/*/tests/
    rm -rf dist/$ARCH/lib/python3.10/__pycache__
    rm -rf dist/$ARCH/lib/python3.10/plat-*
    rm -rf dist/$ARCH/lib/python3.10/config-*
    rm -rf dist/$ARCH/lib/python3.10/tkinter
    rm -rf dist/$ARCH/lib/python3.10/lib-*

    # Copy python
    cp -RL dist/$ARCH/lib/libpython3.10.so $PREFIX/android/$ARCH/lib/
    cp -RL dist/$ARCH/include $PREFIX/android/$ARCH
    cp -RL dist/$ARCH/lib/python3.10/* $PREFIX/android/$ARCH/python

    # exit 1
done

# Some reason I have to patch conda to ignore a __pycache__ error during packaging after everything
# find $PREFIX/android/ -name "*.pyc" -exec rm -rf {} || true \;
