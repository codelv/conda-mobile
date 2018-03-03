#!/usr/bin/env bash

export TARGETS=("iphoneos iphonesimulator android/arm android/arm64 android/x86 android/x86_64")

# Install runtime source in each target
for TARGET in $TARGETS
do
    # Install actual
    mkdir -p $PREFIX/$TARGET/python/site-packages
    cp -RL src/enamlnative $PREFIX/$TARGET/python/site-packages
done


# Install android lib
cp -RL android $PREFIX/android/$PKG_NAME

# Install ios lib
# TODO....