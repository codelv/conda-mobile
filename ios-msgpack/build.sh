#!/usr/bin/env bash

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

    export APP_ROOT=$ROOT/$SDK
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


    # Clean and build
    rm -f msgpack/_packer.cpp
	rm -f msgpack/_unpacker.cpp
	rm -rf msgpack/__pycache__
	rm -rf test/__pycache__
    make cython
    python setup.py build

done

mkdir $PREFIX/iphoneos/
mkdir $PREFIX/iphoneos/python/
mkdir $PREFIX/iphoneos/python/site-packages/
mkdir $PREFIX/iphonesimulator/
mkdir $PREFIX/iphonesimulator/python/
mkdir $PREFIX/iphonesimulator/python/site-packages/

# Copy to output
cp -RL build/lib.darwin-arm-2.7/msgpack $PREFIX/iphoneos/python/site-packages/
cp -RL build/lib.darwin-x86_64-2.7/msgpack $PREFIX/iphonesimulator/python/site-packages/

# Lipo the so files iphone
SOFILES="msgpack/_packer msgpack/_unpacker"
for SOFILE in $SOFILES
do

    # Merge iphoneos versions
    rm $PREFIX/iphoneos/python/site-packages/$SOFILE.so
    lipo -create build/lib.darwin-arm-2.7/$SOFILE.so \
                 build/lib.darwin-aarch64-2.7/$SOFILE.so \
                 -o $PREFIX/iphoneos/python/site-packages/$SOFILE.dylib

    # Rename simulator versions
    rm $PREFIX/iphonesimulator/python/site-packages/$SOFILE.so

    lipo -create build/lib.darwin-i386-2.7/$SOFILE.so \
                 build/lib.darwin-x86_64-2.7/$SOFILE.so \
                -o $PREFIX/iphonesimulator/python/site-packages/$SOFILE.dylib
done
