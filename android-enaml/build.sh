#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Feb 23, 2018
# ==================================================================================================
export HOSTPYTHON=$PYTHON
source $BUILD_PREFIX/android/activate-ndk.sh

if [ "$PY3K" == "1" ]; then
    export PY_LIB_VER="3.10"
else
    export PY_LIB_VER="2.7"
fi

# Install in host python
python setup.py develop

# Write parse tables
python $RECIPE_DIR/write_tables.py


for ARCH in $ARCHS
do

    # Setup compiler for arch and target_api
    activate-ndk-clang $ARCH
    export CFLAGS="$CFLAGS -O3 -I$APP_ROOT/include/python$PY_LIB_VER"
    export LDFLAGS="$LDFLAGS -lpython$PY_LIB_VER"
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
    validate-lib-arch $PREFIX/android/$ARCH/lib/*.so

    # Copy parse tables
    cp -RL $SRC_DIR/enaml/core/parser/parse_tab $PREFIX/android/$ARCH/python/site-packages/enaml/core/parser
    if [ "$PY3K" == "1" ]; then
        rm -f $PREFIX/android/$ARCH/python/site-packages/enaml/core/parser/parse_tab/*2.py
    else
        rm -f $PREFIX/android/$ARCH/python/site-packages/enaml/core/parser/parse_tab/*3*.py
    fi

done

# Cleanup extra files added from running develop
rm -Rf $PREFIX/lib
