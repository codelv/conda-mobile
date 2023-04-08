#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018-2019, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Feb 23, 2018
# ==================================================================================================
export HOSTPYTHON=$PYTHON
source $BUILD_PREFIX/android/activate-ndk.sh

if [ "$PY_VER" != "3.11" ]; then
    echo "Please build with boa/conda's --python=3.11 flag"
    exit 1
fi

sed -i "s/setup(/setup(name='kiwisolver', version='$PKG_VERSION',/g" setup.py


for ARCH in $ARCHS
do

    # Setup compiler for arch and target_api
    activate-ndk-clang $ARCH

    export CFLAGS="$CFLAGS -O3 -I$APP_ROOT/include/python$PY_VER"
    export LDFLAGS="$LDFLAGS -lpython$PY_VER"
    export LDSHARED="$CXX -shared"
    export CROSS_COMPILE="$ARCH"
    export CROSS_COMPILE_TARGET='yes'
    export _PYTHON_HOST_PLATFORM="android-$ARCH"

    # Build
    python setup.py build

    # Rename and move all so files to lib
    export PY_BUILD_DIR="build/lib.android-$ARCH-cpython-${PY_VER/./''}"
    cd $PY_BUILD_DIR
        find * -type f -name "*.so" -exec rename 's!/!.!g' {} \;
        rename 's/^/lib./' *.so; rename 's/\.cpython-.+\.so/\.so/' *.so;
    cd $SRC_DIR

    # Copy to install
    cp -RL kiwi $PREFIX/android/$ARCH/include
    mkdir -p $PREFIX/android/$ARCH/python/site-packages/
    cp -RL $PY_BUILD_DIR/kiwisolver $PREFIX/android/$ARCH/python/site-packages/
    cp -RL $PY_BUILD_DIR/*.so $PREFIX/android/$ARCH/lib
    validate-lib-arch $PREFIX/android/$ARCH/lib/*.so
done
