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

# Disable LFS
#sed -ie "s!use_lfs=yes!use_lfs=no!g" configure

# Conda patches can fail silently so use these for debugging

for ARCH in $ARCHS
do
    # Setup compiler for arch and target_api
    activate-ndk-clang $ARCH 32

    export CFLAGS="-fPIC -I$APP_ROOT/include"
    export LDFLAGS="-L$APP_ROOT/lib -L$NDK_LIB_DIR -llog" # -lffi -lssl -lcrypto"

    cp $RECIPE_DIR/Setup.local $SRC_DIR/Modules/
    export _PYTHON_HOST_PLATFORM="$TARGET_HOST"
    ./configure \
        ac_cv_file__dev_ptmx=yes \
        ac_cv_file__dev_ptc=no \
        ac_cv_have_long_long_format=yes \
        --with-build-python=$PYTHON \
        --with-openssl=$APP_ROOT/include/openssl \
        --with-ensurepip=install \
        --with-lto \
        --host=$TARGET_HOST \
        --build=$ARCH \
        --enable-ipv6 \
        --enable-optimizations \
        --enable-shared

    sed -i 's!$(BLDSHARED) -o!$(BLDSHARED) -Wl,-soname,$(INSTSONAME) -o!g' Makefile

    make clean

    # Build libpython
    make -j$CPU_COUNT libpython3.so

    # Now build the extensions and be sure to explicitly link python
    # The new setup.py build has all kinds of errors so use the old school way
    # To anyone that wants to try with setup.py have fun :)
    make -j$CPU_COUNT oldsharedmods LDFLAGS="$LDFLAGS -L. -lpython3.10 -landroid"
    make -C $SRC_DIR install prefix=$SRC_DIR/dist/$ARCH

    # Remove unused stuff
    rm -Rf dist/$ARCH/lib/python3.10/test
    rm -Rf dist/$ARCH/lib/python3.10/*/test/
    rm -Rf dist/$ARCH/lib/python3.10/*/tests/
    rm -Rf dist/$ARCH/lib/python3.10/plat-*
    rm -Rf dist/$ARCH/lib/python3.10/lib-*
    rm -Rf dist/$ARCH/lib/python3.10/config-*
    rm -Rf dist/$ARCH/lib/python3.10/tkinter

    mkdir -p $PREFIX/android/$ARCH/lib
    mkdir -p $PREFIX/android/$ARCH/python

    # Prefix with lib., remove cpython-310 from name, remove module from name, and copy extensions
    cd Modules; rename 's/^/lib./' *.so; rename 's/.cpython-310//' *.so; rename 's/module//' *.so; cd ..
    find Modules -type f -name "*.so" -exec cp {} "$PREFIX/android/$ARCH/lib/" \;

    # Copy python
    cp -RL dist/$ARCH/lib/libpython3.10.so $PREFIX/android/$ARCH/lib/
    cp -RL dist/$ARCH/include $PREFIX/android/$ARCH
    cp -RL dist/$ARCH/lib/python3.10/* $PREFIX/android/$ARCH/python

done

# Some reason I have to patch conda to ignore a __pycache__ error during packaging after everything
# find $PREFIX/android/ -name "*.pyc" -exec rm -rf {} || true \;
