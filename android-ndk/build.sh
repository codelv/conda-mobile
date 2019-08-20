#!/usr/bin/env bash
export SDK="android"
export NDK="$HOME/Android/Sdk/ndk-bundle"
export ARCHS=("x86_64 x86 arm arm64")

repo init -u https://android.googlesource.com/platform/manifest -b gcc
repo forall -c git checkout ndk-r16-release
repo sync

# Enable fortran
sed -i.bak 's/ENABLE_LANGUAGES="c,c++"/ENABLE_LANGUAGES="c,c++,fortran"/g' toolchain/gcc/build-gcc.sh

# Enable shared
#sed -i.bak 's/ --disable-shared//g' toolchain/build/Makefile.in

# Patch x86
patch -t -d $SRC_DIR -p1 -i $RECIPE_DIR/x86.diff

# Build 
cd toolchain/gcc
python build.py
