

# Patch
sed -i.bak s/-miphoneos-version-min=5.1.1/-miphoneos-version-min=8.0/g \
    generate-darwin-source-and-headers.py

patch -t -d $SRC_DIR \
      -p1 -i $RECIPE_DIR/fix-win32-unreferenced-symbol.patch

# Copy project
cp -R $RECIPE_DIR/libffi.xcodeproj $SRC_DIR

# Prepare
./autogen.sh

# Build iphoneos
export SDK="iphoneos"
xcodebuild -sdk $SDK \
           -project libffi.xcodeproj \
           -target libffi-iOS \
           -configuration Release

mkdir $PREFIX/$SDK
cp -R build/Release-$SDK/ $PREFIX/$SDK
cp -R build_$SDK-armv7/include $PREFIX/$SDK

# Build iphonesimulator
export SDK="iphonesimulator"

xcodebuild -sdk $SDK \
           -project libffi.xcodeproj \
           -target libffi-iOS \
           -configuration Release

mkdir $PREFIX/$SDK
cp -R build/Release-$SDK/* $PREFIX/$SDK
cp -R build_$SDK-x86_64/include $PREFIX/$SDK