
export DEVELOPER="$(xcode-select -print-path)"
export VERSION_MIN="-miphoneos-version-min=8.0.0"
export BUILD_TOOLS="${DEVELOPER}"
#export ARCHS=("armv7 arm64 i386 x86_64")
export ARCHS=("armv7 arm64 x86_64")

for ARCH in $ARCHS
do
    if [ "$ARCH" == "armv7" ] || [ "$ARCH" == "arm64" ]; then
        export SDK="iphoneos"
        export PLATFORM="iPhoneOS"
        export TARGET="iphoneos-cross"
    else
        export SDK="iphonesimulator"
        export PLATFORM="iPhoneSimulator"
        if [ "$ARCH" == "x86_64" ]; then
            export TARGET="darwin64-$ARCH-cc"
        else
            export TARGET="darwin-$ARCH-cc"
        fi
    fi

    export SYSROOT="$(xcrun --sdk $SDK --show-sdk-path)"
    export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
    export CROSS_SDK="$PLATFORM$(xcrun --sdk $SDK --show-sdk-platform-version).sdk"
    export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH}"

    # Configure for iphoneos
    perl Configure \
         $TARGET \
         -shared \
         --prefix=@rpath \

    # Clean
    make clean

    # Patch cflags
    export CFLAGS="-pipe -isysroot $SYSROOT -O3 $VERSION_MIN -DOPENSSL_THREADS -D_REENTRANT -fomit-frame-pointer"
    sed -ie "s!^CFLAG=.*!CFLAG=$CFLAGS !g" Makefile

    make -j$CPU_COUNT build_libs LIBDIR=.


    # Copy to install dir
    mkdir $ARCH
    mv libcrypto*.dylib $ARCH/
    mv libssl*.dylib $ARCH/

done

mkdir $PREFIX/iphoneos
mkdir $PREFIX/iphonesimulator

# Merge iphoneos libs
lipo -create -arch armv7 armv7/libssl.1.0.0.dylib \
             -arch arm64 arm64/libssl.1.0.0.dylib \
             -output $PREFIX/iphoneos/libssl.dylib

lipo -create -arch armv7 armv7/libcrypto.1.0.0.dylib \
             -arch arm64 arm64/libcrypto.1.0.0.dylib \
             -output $PREFIX/iphoneos/libcrypto.dylib
cp -RL include $PREFIX/iphoneos

# Merge simulator libs
#lipo -create i386/libssl*.dylib x86_64/libssl*.dylib \
#     -output $PREFIX/iphoneos/libssl.dylib
#
#lipo -create i386/libcrypto*.dylib x86_64/libcrypto*.dylib \
#     -output $PREFIX/iphoneos/libcrypto.dylib
mv x86_64/libcrypto.1.0.0.dylib $PREFIX/iphonesimulator/libcrypto.dylib
mv x86_64/libssl.1.0.0.dylib $PREFIX/iphonesimulator/libssl.dylib
cp -RL include $PREFIX/iphonesimulator

# Merge iphone sim libs
#exit 77
