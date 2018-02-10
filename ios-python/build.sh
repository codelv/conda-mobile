
export HOSTPYTHON="$(which python2)"
export VERSION_MIN="-miphoneos-version-min=8.0.0"
#export ARCHS=("x86_64 arm64 armv7")
# TODO: x86_64 doesnt work? It's trying to build libffi dispite the --with-system-ffi flag...
export ARCHS=("armv7 arm64")

# Patch
patch -t -d $SRC_DIR -p1 -i $RECIPE_DIR/patches/xcompile.patch
patch -t -d $SRC_DIR -p1 -i $RECIPE_DIR/patches/posixmodule.patch



for ARCH in $ARCHS
do

    if [ "$ARCH" == "armv7" ]; then
        export SDK="iphoneos"
        export TARGET_HOST="$ARCH-apple-darwin"
    elif [ "$ARCH" == "arm64" ]; then
        export SDK="iphoneos"
        export TARGET_HOST="aarch64-apple-darwin"
    else
        export SDK="iphonesimulator"
        export TARGET_HOST="$ARCH-apple-darwin"
    fi

    export APP_ROOT=$ROOT/envs/testapp/$SDK
    export SYSROOT="$(xcrun --sdk $SDK --show-sdk-path)"

    # Copy modules and update SSL path
    #cp $RECIPE_DIR/Setup.local $SRC_DIR/Modules/
    #sed -i.bak s!SSL=/usr/local/ssl!SSL=$APP_ROOT/$SDK/include/!g $SRC_DIR/Modules/Setup.local

    #export USE_CCACHE="1"
    #export CCACHE="$(which ccache)"
    export CC="$(xcrun -find -sdk $SDK gcc)"
    export CFLAGS="-arch $ARCH -pipe --sysroot $SYSROOT -O3 $VERSION_MIN -I$APP_ROOT/include"
    export AR="$(xcrun -find -sdk $SDK ar)"
    export CXX="$(xcrun -find -sdk $SDK g++)"
    export LD="$(xcrun -find -sdk $SDK ld)"
    export LDFLAGS="-arch $ARCH --sysroot $SYSROOT $VERSION_MIN -L$APP_ROOT -lsqlite3 -lffi -lssl -lcrypto"


    ./configure ac_cv_file__dev_ptmx=no \
                ac_cv_file__dev_ptc=no \
                --prefix=$PREFIX \
                --without-pymalloc \
                --disable-toolbox-glue \
                --host=$TARGET_HOST \
                --build=$BUILD \
                --enable-ipv6 \
                --enable-shared \
                --with-system-ffi \
                --without-doc-strings

    make clean


    if [ "$ARCH" == "arm64" ]; then
        FIND='#define HAVE_GETENTROPY 1'
        REPLACE='/* #undef HAVE_GETENTROPY */'
        sed -i.bak "s!$FIND!$REPLACE!g" pyconfig.h
    fi

    make -j$CPU_COUNT CROSS_COMPILE_TARGET=yes


    # Make compileall ignore everything
    REPLACE='\$(DESTDIR)\$(LIBDEST)/compileall.py'
    sed -i.bak s!$REPLACE!$RECIPE_DIR/patches/nocompile.py!g Makefile

    make -C $SRC_DIR install CROSS_COMPILE_TARGET=yes \
                    prefix=$SRC_DIR/dist/$ARCH


done


mkdir $PREFIX/iphoneos
mkdir $PREFIX/iphonesimulator

# Make a single lib with both for the iphone
lipo -create -arch armv7 dist/armv7/lib/libpython2.7.dylib \
             -arch arm64 dist/arm64/lib/libpython2.7.dylib \
             -o $PREFIX/iphoneos/libpython2.7.dylib

# Copy headers and stdlib
cp -RL dist/armv7/include $PREFIX/iphoneos/
cp -RL dist/armv7/lib/python2.7 $PREFIX/iphoneos/


#cp -RL dist/x86_64/lib/ $PREFIX/iphonesimulator/
#cp -RL dist/x86_64/include $PREFIX/iphonesimulator/
#cp -RL dist/x86_64/lib/python2.7 $PREFIX/iphonesimulator/


# Use this to debug the outputs
#exit 1