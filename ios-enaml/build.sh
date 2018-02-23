#!/usr/bin/env bash
# ==================================================================================================
# Copyright (c) 2018, Jairus Martin.
# Distributed under the terms of the MIT License.
# The full license is in the file LICENSE, distributed with this software.
# Created on Feb 22, 2018
# ==================================================================================================

export HOSTPYTHON="$(which python2)"
export VERSION_MIN="-miphoneos-version-min=8.0.0"
export ARCHS=("armv7 arm64 x86_64 i386")

for ARCH in $ARCHS
do

    if [ "$ARCH" == "armv7" ]; then
        export SDK="iphoneos"
        export TARGET_HOST="armv7-apple-darwin"
        export LOCAL_ARCH="arm"
    elif [ "$ARCH" == "arm64" ]; then
        export SDK="iphoneos"
        export TARGET_HOST="aarch64-apple-darwin"
        export LOCAL_ARCH="aarch64"
    else
        export SDK="iphonesimulator"
        export TARGET_HOST="$ARCH-apple-darwin"
        export LOCAL_ARCH=$ARCH
    fi

    export APP_ROOT="$PREFIX/$SDK"
    export SYSROOT="$(xcrun --sdk $SDK --show-sdk-path)"

    export CC="$(xcrun -find -sdk $SDK gcc)"
    export AR="$(xcrun -find -sdk $SDK ar)"
    export LD="$(xcrun -find -sdk $SDK ld)"
    export CXX="$(xcrun -find -sdk $SDK g++)"
    export CFLAGS="-arch $ARCH -pipe -O3 $VERSION_MIN -isysroot $SYSROOT -I$APP_ROOT/include/python2.7"
    export LDFLAGS="-arch $ARCH -L$SYSROOT/usr/lib -L$APP_ROOT/lib -lpython2.7"
    export LDSHARED="$CXX -bundle"
    export CROSS_COMPILE="$ARCH"
    export CROSS_COMPILE_TARGET='yes'
    export _PYTHON_HOST_PLATFORM="darwin-$LOCAL_ARCH"

    # Build
    python setup.py build

done


mkdir -p $PREFIX/iphoneos/python/site-packages/
mkdir -p $PREFIX/iphonesimulator/python/site-packages/

# Copy to output
cp -RL build/lib.darwin-arm-2.7/enaml $PREFIX/iphoneos/python/site-packages/
cp -RL build/lib.darwin-x86_64-2.7/enaml $PREFIX/iphonesimulator/python/site-packages/

# Lipo the so files iphone
SOFILES="enaml/callableref enaml/core/dynamicscope enaml/core/alias enaml/core/declarative_function enaml/core/funchelper enaml/c_compat enaml/signaling enaml/fontext enaml/colorext enaml/weakmethod"
for SOFILE in $SOFILES
do
    # Convert all / to .
    DYFILE=${SOFILE//\//.}

    # Merge iphoneos versions
    rm $PREFIX/iphoneos/python/site-packages/$SOFILE.so
    lipo -create build/lib.darwin-arm-2.7/$SOFILE.so \
                 build/lib.darwin-aarch64-2.7/$SOFILE.so \
                 -o $PREFIX/iphoneos/lib/$DYFILE.dylib

    # Rename simulator versions
    rm $PREFIX/iphonesimulator/python/site-packages/$SOFILE.so

    lipo -create build/lib.darwin-i386-2.7/$SOFILE.so \
                 build/lib.darwin-x86_64-2.7/$SOFILE.so \
                -o $PREFIX/iphonesimulator/lib/$DYFILE.dylib
done
