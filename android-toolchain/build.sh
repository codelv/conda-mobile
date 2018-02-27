#!/usr/bin/env bash

export SDK="android"
export NDK="$HOME/Android/Sdk/ndk-bundle"
export ARCHS=("x86_64 x86 arm arm64")

for ARCH in $ARCHS
do
    # Make the toolchain
    python $NDK/build/tools/make_standalone_toolchain.py \
                                            --arch $ARCH \
                                            --api 26 \
                                            --stl=libc++ \
                                            --install-dir=$PREFIX/android/toolchains/$ARCH
done