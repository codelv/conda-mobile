#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Feb 23, 2018
# ==================================================================================================
export HOSTPYTHON=$PYTHON
export ARCHS=("x86_64 x86 arm arm64")
export NDK="$HOME/Android/Sdk/ndk-bundle"

if [ "$PY3K" == "1" ]; then
    export PY_LIB_VER="3.7m"
else
    export PY_LIB_VER="2.7"
fi

# Install in host python
python setup.py develop

# Write parse tables
python $RECIPE_DIR/write_tables.py


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
    export CC="$TARGET_HOST-clang"
    export CXX="$TARGET_HOST-clang++"
    export LD="$TARGET_HOST-ld"
    export STRIP="$TARGET_HOST-strip"
    export CFLAGS="-O3 -I$APP_ROOT/include/python$PY_LIB_VER"
    export LDFLAGS="-L$APP_ROOT/lib -lpython$PY_LIB_VER"
    export LDSHARED="$CXX -shared"
    export CROSS_COMPILE="$ARCH"
    export CROSS_COMPILE_TARGET='yes'
    export _PYTHON_HOST_PLATFORM="android-$ARCH"

    # Build
    python setup.py build

    # Rename and move all so files to lib
    cd build/lib.android-$ARCH-$PY_VER/
        find * -type f -name "*.so" -exec rename 's!/!.!g' {} \;
        rename 's/^/lib./' *.so; rename 's/\.cpython-.+\.so/\.so/' *.so;
    cd $SRC_DIR

    # Copy to install
    mkdir -p $PREFIX/android/$ARCH/python/site-packages/
    cp -RL build/lib.android-$ARCH-$PY_VER/enaml $PREFIX/android/$ARCH/python/site-packages/
    cp -RL build/lib.android-$ARCH-$PY_VER/*.so $PREFIX/android/$ARCH/lib

    # Copy parse tables
    cp -RL $SP_DIR/enaml/core/parser/parse_tab $PREFIX/android/$ARCH/python/site-packages/enaml/core/parser
    if [ "$PY3K" == "1" ]; then
        rm -f $PREFIX/android/$ARCH/python/site-packages/enaml/core/parser/parse_tab/*2.py
    else
        rm -f $PREFIX/android/$ARCH/python/site-packages/enaml/core/parser/parse_tab/*3*.py
    fi
done

# Cleanup extra files added from running develop
rm -Rf $PREFIX/lib
