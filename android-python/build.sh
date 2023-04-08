#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the GPL v3 License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Feb 23, 2018
# ==================================================================================================
source "$BUILD_PREFIX"/android/activate-ndk.sh

set -e

# Change insoname
sed -i 's!INSTSONAME="$LDLIBRARY".$SOVERSION!INSTSONAME="$LDLIBRARY"!g' configure
sed -i 's!$(VERSION)$(ABIFLAGS)!$(VERSION)!g' configure

# Add patch for parsing conda's python version header
python "$RECIPE_DIR"/brand_python.py

sed -i 's!self.inc_dirs = (self.compiler.include_dirs +!self.inc_dirs = (self.compiler.include_dirs + [os.environ["APP_ROOT"] + "/include", os.environ["NDK_INC_DIR"]] + !g' "$SRC_DIR"/setup.py

export LD_RUN_PATH="$PREFIX/lib"

for ARCH in $ARCHS
do
    # Setup compiler for arch and target_api
    activate-ndk-clang "$ARCH"

    export CFLAGS="$CFLAGS -fPIC"
    export CCSHARED="$CFLAGS -DPy_BUILD_CORE"
    export SSL="$APP_ROOT"
    export LDFLAGS="$LDFLAGS --sysroot=$ANDROID_TOOLCHAIN/sysroot -llog"
    export _PYTHON_HOST_PLATFORM="$TARGET_HOST"

    ./configure \
        ac_cv_file__dev_ptmx=yes \
        ac_cv_file__dev_ptc=no \
        ac_cv_have_long_long_format=yes \
        --with-build-python="python$PY_VER" \
        --with-ensurepip=install \
        --with-openssl="$APP_ROOT" \
        --with-lto \
        --host="$TARGET_HOST" \
        --build="$ARCH" \
        --enable-ipv6 \
        --enable-shared

    # Set soname and support for libs < 23
    sed -i 's!$(BLDSHARED) -o!$(BLDSHARED) -Wl,--hash-style=both -Wl,-soname,$(INSTSONAME) -o!g' Makefile

    make clean

    # Change config
    sed -i 's!\/\* #undef HAVE_BROKEN_POSIX_SEMAPHORES \*\/!#define HAVE_BROKEN_POSIX_SEMAPHORES 1!g' pyconfig.h
    sed -i 's!#define HAVE_GETLOADAVG 1!/* #undef HAVE_GETLOADAVG */!g' pyconfig.h
    sed -i 's!#define HAVE_MEMFD_CREATE 1!/* #undef HAVE_MEMFD_CREATE */!g' pyconfig.h

    # Build libpython
    make -j"$CPU_COUNT" libpython3.so

    # New script now works but skips some modules like ssl, sqlite
    # so stay with the old..
    make -j"$CPU_COUNT" sharedmods LDFLAGS="$LDFLAGS -L. -lpython$PY_VER -landroid"
    make -C "$SRC_DIR" install prefix="$SRC_DIR/dist/$ARCH"

    # Remove example/test modules
    rm dist/"$ARCH"/lib/python"$PY_VER"/lib-dynload/xxlim*.so
    rm dist/"$ARCH"/lib/python"$PY_VER"/lib-dynload/_xx*.so
    rm dist/"$ARCH"/lib/python"$PY_VER"/lib-dynload/*test*.so

    mkdir -p "$PREFIX/android/$ARCH/lib"
    mkdir -p "$PREFIX/android/$ARCH/python"

    # Prefix with lib., remove cpython-310 from name, remove module from name, and copy extensions
    # If using oldsharedmods this should just be Modules
    export MOD_DIR="dist/$ARCH/lib/python$PY_VER/lib-dynload"
    export MOD_SUFFIX=".cpython-${PY_VER/./}"
    cd "$MOD_DIR"
    for f in *.so; do
      mv "$f" "lib.${f//MOD_SUFFIX/}";
    done
    for f in *.so; do
      test "$f" != "*module*" && continue
      mv "$f" "${f//module/}";
    done
    cd "$SRC_DIR"
    find "$MOD_DIR" -type f -name "*.so" -exec cp {} "$PREFIX/android/$ARCH/lib/" \;

    # Remove unused stuff
    rm -rf dist/"$ARCH"/lib/python"$PY_VER"/test
    rm -rf dist/"$ARCH"/lib/python"$PY_VER"/*/test/
    rm -rf dist/"$ARCH"/lib/python"$PY_VER"/*/tests/
    rm -rf dist/"$ARCH"/lib/python"$PY_VER"/__pycache__
    rm -rf dist/"$ARCH"/lib/python"$PY_VER"/plat-*
    rm -rf dist/"$ARCH"/lib/python"$PY_VER"/config-*
    rm -rf dist/"$ARCH"/lib/python"$PY_VER"/tkinter
    rm -rf dist/"$ARCH"/lib/python"$PY_VER"/lib-*

    # Copy python
    cp -RL dist/"$ARCH"/lib/libpython"$PY_VER".so "$PREFIX"/android/"$ARCH"/lib/
    cp -RL dist/"$ARCH"/include "$PREFIX"/android/"$ARCH"
    cp -RL dist/"$ARCH"/lib/python"$PY_VER"/* "$PREFIX"/android/"$ARCH"/python
    validate-lib-arch "$PREFIX"/android/"$ARCH"/lib/*.so

    # exit 1
done

# Some reason I have to patch conda to ignore a __pycache__ error during packaging after everything
# find $PREFIX/android/ -name "*.pyc" -exec rm -rf {} || true \;
