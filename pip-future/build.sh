#!/usr/bin/env bash

export TARGETS=("iphoneos iphonesimulator android/arm android/arm64 android/x86 android/x86_64")

# Install in each target
for TARGET in $TARGETS
do
    pip install future==$PKG_VERSION --target=$PREFIX/$TARGET/python/site-packages
done