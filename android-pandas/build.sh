#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on May 2, 2018
# ==================================================================================================
export HOSTPYTHON=$PYTHON
source $BUILD_PREFIX/android/activate-ndk.sh

patch -t -d $SRC_DIR -p1 -i $RECIPE_DIR/compat.patch

if [ "$PY3K" == "1" ]; then
    export PY_LIB_VER="3.10"
else
    export PY_LIB_VER="2.7"
fi

for ARCH in $ARCHS
do

       # Setup compiler for arch and target_api
    activate-ndk-clang $ARCH

    export CFLAGS="-O3 -I$APP_ROOT/include/python$PY_LIB_VER -I$APP_ROOT/include/"
    export LDFLAGS="-L$APP_ROOT/lib -L$NDK_LIB_DIR -lpython$PY_LIB_VER"
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

    # Clean tests
    rm -Rf build/lib.android-$ARCH-$PY_VER/pandas/tests

    # Copy to install
    mkdir -p $PREFIX/android/$ARCH/python/site-packages/
    cp -RL build/lib.android-$ARCH-$PY_VER/pandas $PREFIX/android/$ARCH/python/site-packages/
    cp -RL build/lib.android-$ARCH-$PY_VER/*.so $PREFIX/android/$ARCH/lib
    validate-lib-arch $PREFIX/android/$ARCH/lib/*.so

done
